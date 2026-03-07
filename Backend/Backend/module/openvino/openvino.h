// 遂沫 openvino.h
// 2026-02-22 18:39:03

#pragma once
#include <openvino/openvino.hpp>
#include "module/ModelBackend.h"

namespace module {
    class OpenVINOImpl final : public ModelBackendAbstract, BackendRegistry<OpenVINOImpl> {
    public:
        using Detection = std::pair<int, cv::Rect>;
        inline static const auto BackendName = "OpenVINO";

        OpenVINOImpl();
        ~OpenVINOImpl() override = default;

        auto load(const std::filesystem::path& path) -> bool override;
        auto infer(const cv::Mat& frame) -> std::optional<std::vector<std::pair<int, cv::Rect>>> override;
        auto set_device(const std::string& device_name) -> bool override;
        auto get_devices() -> std::vector<DeviceInfo> override;
    private:
        auto get_shape_size() const -> void;
        auto pre_processing(const cv::Mat& frame) -> void;
        auto post_processing_nms() -> std::vector<Detection>;
        static auto get_bounding_box_nms(const cv::Rect& src) -> cv::Rect;
        static auto get_bounding_box_no_nms(const cv::Rect& src) -> cv::Rect;
        auto post_processing_no_nms() -> std::vector<Detection>;

        ov::Core core;
        ov::CompiledModel compiled_model;
        ov::InferRequest inference_request;
        std::atomic<std::shared_ptr<ov::Model>> model;
    };
} // namespace module
