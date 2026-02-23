// 遂沫 screenshot.cpp
// 2026-02-22 17:36:26

#include "screenshot.h"
#include "page/preveiw/preveiw.h"
#include "stdpp/encode.h"

#include <chrono>

using namespace std::chrono_literals;
using namespace module;
using namespace page;

auto Screenshot::get_monitor() -> std::vector<std::string> {
    monitors = stdpp::screen::MonitorInfo::get_monitors();

    std::vector<std::string> str;
    str.reserve(monitors.size());
    for (auto& monitor : monitors) {
        str.push_back(stdpp::encode::wchar_to_char(monitor.monitor_name));
    }
    return str;
}

auto Screenshot::start_monitor() -> void {
    stop_monitor();
    jthread = std::jthread([](const std::stop_token& stoken) {
        cv::Mat temp;
        while (!stoken.stop_requested()) {
            const std::chrono::time_point<std::chrono::steady_clock> frame_start = std::chrono::steady_clock::now();

            const auto ins = PreviewPage::instance();
            int target_width;
            int target_height;
            {
                auto _ = ins->window_height.read_lock();
                auto _ = ins->window_width.read_lock();
                target_width = *ins->window_width;
                target_height = *ins->window_height;
            }

            if (capture(temp, {target_width, target_height})) {
                std::unique_lock lock(mutex);
                frame = temp.clone();
            }

            ins->put_image(temp);
            fps_limit(frame_start);
        }
    });
}

auto Screenshot::stop_monitor() -> void {
    if (jthread.joinable()) {
        jthread.request_stop();
        jthread.detach();
    }

    {
        std::unique_lock lock(mutex);
        frame = cv::Mat();
    }
}

auto Screenshot::fps_limit(const std::chrono::time_point<std::chrono::steady_clock> frame_start) -> void {
    const auto ins = PreviewPage::instance();

    auto _ = ins->fps_limit.read_lock();
    if (const float target_fps = *ins->fps_limit; target_fps > 0) {
        const auto frame_end = std::chrono::steady_clock::now();
        const auto frame_duration = frame_end - frame_start;

        if (const auto target_frame_time = std::chrono::microseconds(static_cast<int>(1000000.0f / target_fps)); frame_duration < target_frame_time) {
            const auto sleep_time = target_frame_time - frame_duration;
            std::this_thread::sleep_for(sleep_time);
        }
    }
}

auto Screenshot::capture(cv::Mat& frame_temp, const cv::Size size) -> bool {
    const int target_width = size.width;
    const int target_height = size.height;

    if (isWindow && (!hwnd || !IsWindow(hwnd))) {
        return false;
    }

    cv::Size screen_size;
    if (isWindow) {
        screen_size = stdpp::screen::ScreenshotManager::window_size(hwnd);
    } else {
        screen_size = stdpp::screen::ScreenshotManager::size();
    }

    if (target_width > 0 && target_height > 0) {
        const int center_x = screen_size.width / 2;
        const int center_y = screen_size.height / 2;

        int point_x = center_x - target_width / 2;
        int point_y = center_y - target_height / 2;

        point_x = std::max(0, std::min(point_x, screen_size.width - target_width));
        point_y = std::max(0, std::min(point_y, screen_size.height - target_height));

        if (isWindow) {
            stdpp::screen::ScreenshotManager::window(frame_temp, hwnd, cv::Rect(point_x, point_y, target_width, target_height));
        } else {
            stdpp::screen::ScreenshotManager::desktop(frame_temp, cv::Rect(point_x, point_y, target_width, target_height));
        }
    } else {
        if (isWindow) {
            stdpp::screen::ScreenshotManager::window(frame_temp, hwnd);
        } else {
            stdpp::screen::ScreenshotManager::desktop(frame_temp);
        }
    }
    return !frame_temp.empty();
}
