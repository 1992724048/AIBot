// 遂沫 openvino.cpp
// 2026-02-28 23:50:55

#include "openvino.h"

#include "page/backend/backend.h"
#include "page/model/model.h"
#include "page/preveiw/preveiw.h"

#include "stdpp/logger.h"
#include "tbb/tbb.h"

using namespace module;

constexpr auto operator""_hash(const char* str, const size_t len) -> size_t {
    size_t hash = 5381;
    for (size_t i = 0; i < len; ++i) {
        hash = (hash << 5) + hash + str[i];
    }
    return hash;
}

OpenVINOImpl::OpenVINOImpl() {
    BackendRegistry::touch();
}

auto OpenVINOImpl::load(const std::filesystem::path& path) -> bool {
    model = core.read_model(path);
    const auto ptr = model.load();
    if (!ptr) {
        return false;
    }

    auto ppp = ov::preprocess::PrePostProcessor(model);
    ppp.input().tensor().set_element_type(ov::element::u8).set_layout("NHWC").set_color_format(ov::preprocess::ColorFormat::BGR);
    ppp.input().preprocess().convert_element_type(ov::element::f32).convert_color(ov::preprocess::ColorFormat::RGB).scale({255, 255, 255});
    ppp.input().model().set_layout("NCHW");
    ppp.output().tensor().set_element_type(ov::element::f32);
    model = ppp.build();

    if (!model.load()) {
        return false;
    }

    get_shape_size();
    return true;
}

auto OpenVINOImpl::infer(const cv::Mat& frame) -> std::optional<std::vector<std::pair<int, cv::Rect>>> {
    if (!model.load() || frame.empty()) {
        return std::nullopt;
    }

    pre_processing(frame);
    inference_request.infer();

    const auto& type = current_model.load()->type;
    switch (operator""_hash(type.data(), type.size())) {
        case "yolo"_hash:
            return post_processing_nms();
        case "yolo26"_hash:
            return post_processing_no_nms();
        default:
            return std::nullopt;
    }
}

auto OpenVINOImpl::set_device(const std::string& device_name) -> bool {
    if (!current_model.load()) {
        return false;
    }

    if (!model.load()) {
        return false;
    }

    compiled_model = core.compile_model(model.load(), device_name);
    inference_request = compiled_model.create_infer_request();
    return true;
}

auto OpenVINOImpl::get_devices() -> std::vector<DeviceInfo> {
    std::vector<DeviceInfo> devices;
    devices.reserve(3);
    try {
        for (const auto& device_name : core.get_available_devices()) {
            DeviceInfo device;
            if (device_name.contains("CPU")) {
                device.type = BackendDeviceEnum::CPU;
            } else if (device_name.contains("GPU")) {
                device.type = BackendDeviceEnum::GPU;
            } else if (device_name.contains("NPU")) {
                device.type = BackendDeviceEnum::NPU;
            } else {
                continue;
            }
            try {
                device.name = "[" + device_name + "] " + core.get_property(device_name, ov::device::full_name);
            } catch (...) {
                device.name = device_name;
            }
            devices.push_back(device);
        }
        TLOG << "Found " << devices.size() << " OpenVINO devices";
    } catch (const std::exception& e) {
        TLOG << "Error getting OpenVINO devices: " << e.what();
    }
    return devices;
}

auto OpenVINOImpl::get_shape_size() const -> void {
    const auto ptr = model.load();
    const ov::Shape input_shape = ptr->inputs()[0].get_shape();
    input_size = cv::Size(static_cast<int>(input_shape[2]), static_cast<int>(input_shape[1]));

    const ov::Shape output_shape = ptr->outputs()[0].get_shape();
    output_size = cv::Size(static_cast<int>(output_shape[2]), static_cast<int>(output_shape[1]));
}

auto OpenVINOImpl::pre_processing(const cv::Mat& frame) -> void {
    cv::Mat color_frame;
    if (frame.channels() == 4) {
        cvtColor(frame, color_frame, cv::COLOR_BGRA2BGR);
    }

    cv::Mat resized_frame;
    resized_frame.resize(static_cast<size_t>(input_size.height) * input_size.width);
    resize(color_frame, resized_frame, input_size, 0, 0, cv::INTER_AREA);

    scale_factor.x = static_cast<float>(frame.cols) / static_cast<float>(input_size.width);
    scale_factor.y = static_cast<float>(frame.rows) / static_cast<float>(input_size.height);

    ov::Tensor input_tensor = inference_request.get_input_tensor();
    std::memcpy(input_tensor.data<uint8_t>(), resized_frame.data, resized_frame.total() * resized_frame.elemSize());
    inference_request.set_input_tensor(input_tensor);
}

auto OpenVINOImpl::post_processing_nms() -> std::vector<Detection> {
    std::vector<int> class_list;
    std::vector<float> confidence_list;
    std::vector<cv::Rect> box_list;

    const float* detections = inference_request.get_output_tensor().data<const float>();
    const cv::Mat detection_outputs(output_size, CV_32F, const_cast<float*>(detections));

    class_list.reserve(detection_outputs.cols);
    confidence_list.reserve(detection_outputs.cols);
    box_list.reserve(detection_outputs.cols);

    float model_confidence;
    float model_nms;
    {
        const auto ins = page::BackendPage::instance();
        auto _ = ins->confidence.read_lock();
        auto _ = ins->nms.read_lock();
        model_confidence = ins->confidence.value();
        model_nms = ins->confidence.value();
    }

    parallel_for(tbb::blocked_range(0, detection_outputs.cols),
                 [&](const tbb::blocked_range<int>& r) {
                     std::vector<int> local_class_list;
                     std::vector<float> local_confidence_list;
                     std::vector<cv::Rect> local_box_list;

                     for (int i = r.begin(); i < r.end(); ++i) {
                         const cv::Mat classes_scores = detection_outputs.col(i).rowRange(4, detection_outputs.rows);

                         double score = -1.0;
                         int class_id = -1;
                         for (int j = 0; j < classes_scores.rows; ++j) {
                             if (classes_scores.at<float>(j) > score) {
                                 score = classes_scores.at<float>(j);
                                 class_id = j;
                             }
                         }

                         if (score > model_confidence) {
                             local_class_list.push_back(class_id);
                             local_confidence_list.push_back(static_cast<float>(score));

                             const float x = detection_outputs.at<float>(0, i);
                             const float y = detection_outputs.at<float>(1, i);
                             const float w = detection_outputs.at<float>(2, i);
                             const float h = detection_outputs.at<float>(3, i);

                             cv::Rect box;
                             box.x = static_cast<int>(x);
                             box.y = static_cast<int>(y);
                             box.width = static_cast<int>(w);
                             box.height = static_cast<int>(h);
                             local_box_list.push_back(box);
                         }
                     }
                     #pragma omp critical
                     {
                         class_list.insert(class_list.end(), local_class_list.begin(), local_class_list.end());
                         confidence_list.insert(confidence_list.end(), local_confidence_list.begin(), local_confidence_list.end());
                         box_list.insert(box_list.end(), local_box_list.begin(), local_box_list.end());
                     }
                 });

    std::vector<int> nms_result;
    nms_result.reserve(box_list.size());
    cv::dnn::NMSBoxes(box_list, confidence_list, model_confidence, model_nms, nms_result);

    std::vector<Detection> result;
    result.reserve(nms_result.size());
    for (const int id : nms_result) {
        result.emplace_back(class_list[id], get_bounding_box_nms(box_list[id]));
    }
    return result;
}

auto OpenVINOImpl::get_bounding_box_nms(const cv::Rect& src) -> cv::Rect {
    cv::Rect box = src;
    box.x = (box.x - box.width / 2) * scale_factor.x;
    box.y = (box.y - box.height / 2) * scale_factor.y;
    box.width *= scale_factor.x;
    box.height *= scale_factor.y;
    return box;
}

auto OpenVINOImpl::get_bounding_box_no_nms(const cv::Rect& src) -> cv::Rect {
    cv::Rect box = src;
    box.x *= scale_factor.x;
    box.y *= scale_factor.y;
    box.width *= scale_factor.x;
    box.height *= scale_factor.y;
    return box;
}

auto OpenVINOImpl::post_processing_no_nms() -> std::vector<Detection> {
    std::vector<Detection> result;

    const float* detections = inference_request.get_output_tensor().data<const float>();

    const cv::Mat output(output_size, CV_32F, const_cast<float*>(detections));

    float model_confidence;
    {
        const auto ins = page::BackendPage::instance();
        auto _ = ins->confidence.read_lock();
        model_confidence = ins->confidence.value();
    }

    for (int i = 0; i < output.rows; ++i) {
        const float* data = output.ptr<float>(i);

        const float x1 = data[0];
        const float y1 = data[1];
        const float x2 = data[2];
        const float y2 = data[3];
        const float conf = data[4];
        int cls = static_cast<int>(data[5]);

        if (conf < model_confidence) {
            continue;
        }

        cv::Rect box;
        box.x = static_cast<int>(x1);
        box.y = static_cast<int>(y1);
        box.width = static_cast<int>(x2 - x1);
        box.height = static_cast<int>(y2 - y1);

        result.emplace_back(cls, get_bounding_box_no_nms(box));
    }

    return result;
}
