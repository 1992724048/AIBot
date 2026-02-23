// 遂沫 screenshot.h
// 2026-02-22 17:09:09

#pragma once
#include <Windows.h>
#include <shared_mutex>
#include <thread>
#include <stdpp/screen.h>

namespace module {
    class Screenshot {
    public:
        static auto get_monitor() -> std::vector<std::string>;
        static auto start_monitor() -> void;
        static auto stop_monitor() -> void;

        Screenshot() = delete;
        ~Screenshot() = delete;
        Screenshot(const Screenshot& other) = delete;
        Screenshot(Screenshot&& other) noexcept = delete;
        auto operator=(const Screenshot& other) -> Screenshot& = delete;
        auto operator=(Screenshot&& other) noexcept -> Screenshot& = delete;

        inline static std::atomic_bool isWindow;
        inline static std::atomic<HWND> hwnd;

        [[nodiscard]] static auto get_frame() -> std::pair<cv::Mat&, std::shared_lock<std::shared_mutex>> {
            return {frame, std::shared_lock(mutex)};
        }
    private:
        static auto fps_limit(std::chrono::time_point<std::chrono::steady_clock> frame_start) -> void;
        static auto capture(cv::Mat& frame_temp, cv::Size size) -> bool;

        inline static std::shared_mutex mutex;
        inline static cv::Mat frame;
        inline static std::jthread jthread;
        inline static std::vector<stdpp::screen::MonitorInfo> monitors;
    };
} // namespace module
