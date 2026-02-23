// 遂沫 preveiw.h
// 2026-02-22 14:28:10

#pragma once

#include <stdpp/config.h>
#include "stdpp/SingletonRegistry.h"

#include <opencv2/opencv.hpp>

namespace page {
    using namespace stdpp::config;
    using namespace stdpp::singleton;

    class PreviewPage final : public SingletonRegistry<PreviewPage> {
    public:
        PreviewPage();
        ~PreviewPage() override = default;

        Field<float> fps_limit{"fps_limit", 120};
        Field<int> window_height{"window_height", 640};
        Field<int> window_width{"window_width", 640};
        Field<bool> async_capture{"async_capture", true};
        Field<bool> real_time{"real_time", true};
        Field<bool> show_detect{"show_detect", true};
        Field<bool> show_fps{"show_fps", true};
        Field<std::string> desktop_name{"desktop_name", ""};
        Field<std::string> window_name{"window_name", ""};
        Field<std::string> window_class{"window_class", ""};

        auto put_image(const cv::Mat& frame) -> void;
        auto singleton_init() -> void override;
    private:
        int frame_count{0};
        std::chrono::time_point<std::chrono::steady_clock> last_time{std::chrono::steady_clock::now()};
        float current_fps{0.0f};
    };
} // namespace page
