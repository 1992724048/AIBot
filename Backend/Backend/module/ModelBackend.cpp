// 遂沫 ModelBackend.cpp
// 2026-02-28 23:44:05

#include "ModelBackend.h"

#include <ranges>

#include "page/backend/backend.h"

#include "screenshot/screenshot.h"

using namespace module;

auto ModelBackendManager::load(const std::shared_ptr<page::ModelInfo>& model) -> bool {
    std::unique_lock l(mutex);
    current_path = model->path;
    current_model = model;
    dynamic = false;
    if (const auto ptr = current.load()) {
        ptr->load(current_path);
        l.unlock();
        set_device(page::BackendPage::instance()->device_name.value());
        return true;
    }
    return false;
}

auto ModelBackendManager::infer(const cv::Mat& frame) -> std::optional<std::vector<std::pair<int, cv::Rect>>> {
    std::shared_lock _(Screenshot::mutex);
    std::shared_lock _(mutex);
    const auto ptr = current.load();
    return ptr ? ptr->infer(frame) : std::nullopt;
}

auto ModelBackendManager::set_device(const std::string& device_name) -> bool {
    std::unique_lock _(mutex);
    if (const auto ptr = current.load()) {
        std::string extracted_name = device_name;
        const size_t start_pos = device_name.find('[');
        const size_t end_pos = device_name.find(']');

        if (start_pos != std::string::npos && end_pos != std::string::npos && end_pos > start_pos) {
            extracted_name = device_name.substr(start_pos + 1, end_pos - start_pos - 1);
        }

        if (current_model.load()) {
            ptr->load(current_path);
        }
        return ptr->set_device(extracted_name);
    }
    return false;
}

auto ModelBackendManager::get_devices() -> std::vector<DeviceInfo> {
    const auto ptr = current.load();
    return ptr ? ptr->get_devices() : std::vector<DeviceInfo>();
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
