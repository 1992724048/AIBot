// 遂沫 ModelBackend.cpp
// 2026-02-23 21:10:14

#include "ModelBackend.h"

#include <ranges>

using namespace module;

inline auto ModelBackendManager::load(const std::filesystem::path& path) -> bool {
    if (const auto ptr = current.load(); ptr && ptr->load(path)) {
        current_path = path;
        return true;
    }
    return false;
}

inline auto ModelBackendManager::infer(const cv::Mat& frame) -> std::optional<std::vector<cv::Size>> {
    const auto ptr = current.load();
    return ptr ? ptr->infer(frame) : std::nullopt;
}

auto ModelBackendManager::set_device(const std::string& device_name) -> bool {
    if (const auto ptr = current.load()) {
        std::string extracted_name = device_name;
        const size_t start_pos = device_name.find('[');
        const size_t end_pos = device_name.find(']');

        if (start_pos != std::string::npos && end_pos != std::string::npos && end_pos > start_pos) {
            extracted_name = device_name.substr(start_pos + 1, end_pos - start_pos - 1);
        }

        ptr->set_device(extracted_name);
        return true;
    }
    return false;
}

auto ModelBackendManager::get_devices() -> std::vector<DeviceInfo> {
    if (const auto ptr = current.load()) {
        return ptr->get_devices();
    }
    return {};
}

auto ModelBackendManager::select(const std::string& name) -> bool {
    if (select_fn.contains(name)) {
        select_fn[name]();
        return true;
    }
    return false;
}

auto ModelBackendManager::get_backends() -> std::vector<std::string> {
    std::vector<std::string> names;
    for (auto& name : select_fn | std::views::keys) {
        names.push_back(name);
    }
    return names;
}
