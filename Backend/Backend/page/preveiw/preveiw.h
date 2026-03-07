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

        Field<float> fps_limit{"PreviewPage::fps_limit", 120};
        Field<int> window_height{"PreviewPage::window_height", 640};
        Field<int> window_width{"PreviewPage::window_width", 640};
        Field<bool> async_capture{"PreviewPage::async_capture", true};
        Field<bool> real_time{"PreviewPage::real_time", true};
        Field<bool> show_detect{"PreviewPage::show_detect", true};
        Field<bool> show_fps{"PreviewPage::show_fps", true};
        Field<std::string> desktop_name{"PreviewPage::desktop_name", ""};
        Field<std::string> window_name{"PreviewPage::window_name", ""};
        Field<std::string> window_class{"PreviewPage::window_class", ""};

        auto put_image(const cv::Mat& frame) -> void;
        auto singleton_init() -> void override;
    private:
        int frame_count{0};
        std::chrono::time_point<std::chrono::steady_clock> last_time{std::chrono::steady_clock::now()};
        float current_fps{0.0f};
    };
} // namespace page
