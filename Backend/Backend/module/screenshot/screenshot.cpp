// 遂沫 screenshot.cpp
// 2026-02-27 03:23:43

#include "screenshot.h"
#include "page/preveiw/preveiw.h"
#include "stdpp/encode.h"

#include <chrono>

#include "module/ModelBackend.h"

#include "stdpp/thread.hpp"

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
    static stdpp::thread::Pool pool;
    stop_monitor();
    jthread = std::jthread([](const std::stop_token& stoken) {
        cv::Mat temp;
        std::future<std::optional<std::vector<std::pair<int, cv::Rect_<int>>>>> future;
        std::chrono::time_point<std::chrono::steady_clock> frame_start = std::chrono::steady_clock::now();
        while (!stoken.stop_requested()) {
            const auto ins = PreviewPage::instance();
            {
                auto _ = ins->async_capture.read_lock();
                if (!ins->async_capture) {
                    future.wait();
                }
            }

            fps_limit(frame_start);
            frame_start = std::chrono::steady_clock::now();

            int target_width;
            int target_height;
            {
                auto _ = ins->window_height.read_lock();
                auto _ = ins->window_width.read_lock();
                target_width = *ins->window_width;
                target_height = *ins->window_height;
            }

            if (capture(temp, {target_width, target_height})) {
                if (temp.empty()) {
                    continue;
                }
                std::unique_lock lock(mutex);
                frame = temp.clone();
            }

            auto _ = ins->show_detect.read_lock();
            if (future.valid()) {
                future.wait();

                if (ins->show_detect) {
                    if (auto value = future.get()) {
                        for (const auto& [id, box] : value.value()) {
                            rectangle(temp, box, cv::Scalar(0, 255, 0), 2);
                            std::string label = std::format("ID:{}:{}", id, ModelPage::instance()->get_tag_name(id));

                            int baseline = 0;
                            cv::Size text_size = cv::getTextSize(label, cv::FONT_HERSHEY_SIMPLEX, 0.5, 1, &baseline);
                            cv::Rect bg_rect(box.x, box.y - text_size.height - 5, text_size.width, text_size.height + baseline);
                            rectangle(temp, bg_rect, cv::Scalar(0, 255, 0), cv::FILLED);
                            putText(temp, label, {box.x, box.y - 5}, cv::FONT_HERSHEY_SIMPLEX, 0.5, cv::Scalar(0, 0, 0), 1);
                        }
                    }
                }

                ins->put_image(temp);
            }

            future = pool.push(ModelBackendManager::infer, frame);
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
