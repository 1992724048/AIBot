// 遂沫 preveiw.cpp
// 2026-02-23 17:52:49

#include "preveiw.h"

#include "../../module/screenshot/screenshot.h"
#include "flutter_windows/DartFFI.h"
#include "stdpp/encode.h"

using namespace page;
using namespace module;
using namespace flutter;
using namespace flutter::literals;

PreviewPage::PreviewPage() {
    SingletonRegistry::touch();
}

auto PreviewPage::put_image(const cv::Mat& frame) -> void {
    if (real_time) {
        cv::Mat clone = frame.clone();
        frame_count++;
        const auto now = std::chrono::steady_clock::now();
        const auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(now - last_time).count();

        if (duration >= 1000) {
            current_fps = frame_count * 1000.0f / duration;
            frame_count = 0;
            last_time = now;
        }

        if (show_fps) {
            constexpr double base_font_scale = 1.0;
            constexpr int base_thickness = 2;
            constexpr int base_width = 1920;
            constexpr int base_height = 1080;

            double scale = std::min(static_cast<double>(clone.cols) / base_width, static_cast<double>(clone.rows) / base_height);
            scale = std::max(0.5, std::min(3.0, scale));

            const double font_scale = base_font_scale * scale;
            const int thickness = static_cast<int>(base_thickness * scale);
            const int x = static_cast<int>(30 * scale);
            const int y = static_cast<int>(50 * scale);

            putText(clone, "FPS: " + std::to_string(static_cast<int>(current_fps)), cv::Point(x, y), cv::FONT_HERSHEY_SIMPLEX, font_scale, cv::Scalar(0, 255, 0), thickness);
        }

        static std::vector compression_params = {cv::IMWRITE_JPEG_QUALITY, 80};
        std::vector<uint8_t> jpeg_data;
        imencode(".jpg", clone, jpeg_data, compression_params);

        EncodableMap image_info;
        image_info[EncodableValue("width")] = EncodableValue(clone.cols);
        image_info[EncodableValue("height")] = EncodableValue(clone.rows);
        image_info[EncodableValue("format")] = EncodableValue("jpeg");
        image_info[EncodableValue("data")] = EncodableValue(jpeg_data);

        DartFFI::ValueMapArgs args;
        args["mat"] = EncodableValue(image_info);
        try {
            "push_mat"_dart.invoke(args);
        } catch (const std::exception& exception) {
            ELOG << "返回画面出错: " << exception.what();
        } catch (...) {}
    }
}

auto PreviewPage::singleton_init() -> void {
    Dart::field(fps_limit);
    Dart::field(window_height);
    Dart::field(window_width);
    Dart::field(async_capture);
    Dart::field(real_time);
    Dart::field(show_detect);
    Dart::field(show_fps);
    Dart::field(desktop_name);
    Dart::field(window_name);
    Dart::field(window_class);

    desktop_name.add_event([](const std::shared_ptr<FieldEntryBase>& field_entry_base, const Event event) {
        auto monitors = stdpp::screen::MonitorInfo::get_monitors();
        if (monitors.empty()) {
            WMSG(WLOG) << "未检测到显示器!";
            return;
        }

        if (!instance()->desktop_name->empty()) {
            bool find = false;
            for (auto& monitor : monitors) {
                if (instance()->desktop_name.value() == stdpp::encode::wchar_to_char(monitor.monitor_name)) {
                    stdpp::screen::ScreenshotManager::set_mode<stdpp::screen::DesktopDuplicationImpl>(monitor);
                    find = true;
                }
            }
            if (!find) {
                instance()->desktop_name.value().clear();
                instance()->desktop_name.chang(true);
            }
        }
    });

    auto window_event = [](const std::shared_ptr<FieldEntryBase>& field_entry_base, const Event event) {
        if (!instance()->window_name.value().empty() || !instance()->window_class.value().empty()) {
            Screenshot::hwnd = FindWindowA(instance()->window_class.value().empty() ? nullptr : instance()->window_class.value().data(), instance()->window_name.value().data());
            Screenshot::isWindow = true;
        } else {
            Screenshot::isWindow = false;
        }
    };

    window_name.add_event(window_event);
    window_class.add_event(window_event);

    "get_monitor"_dart.method([](DartFFI::ValueMapArgs& map, const DartFFI::Result& method_result) {
        EncodableList list;
        for (auto& monitor : Screenshot::get_monitor()) {
            TLOG << "显示器: " << monitor;
            list.push_back(EncodableValue(monitor));
        }
        method_result->success(EncodableValue(list));
    });

    "start_monitor"_dart.method([](DartFFI::ValueMapArgs& map, const DartFFI::Result& method_result) {
        Screenshot::start_monitor();
        method_result->success();
    });

    "stop_monitor"_dart.method([](DartFFI::ValueMapArgs& map, const DartFFI::Result& method_result) {
        Screenshot::stop_monitor();
        method_result->success();
    });
}
