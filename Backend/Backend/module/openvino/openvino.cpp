// 遂沫 openvino.cpp
// 2026-02-23 01:07:50

#include "openvino.h"

#include "stdpp/logger.h"

using namespace module;

OpenVINOImpl::OpenVINOImpl() {
    BackendRegistry::touch();
}

auto OpenVINOImpl::load(const std::filesystem::path& path) -> bool {}

auto OpenVINOImpl::infer(const cv::Mat& frame) -> std::optional<std::vector<cv::Size>> {}

auto OpenVINOImpl::set_device(const std::string& device_name) -> void {}

auto OpenVINOImpl::get_devices() -> std::vector<DeviceInfo> {
    std::vector<DeviceInfo> devices;
    try {
        const std::vector<std::string> available_devices = core.get_available_devices();
        for (const auto& device_name : available_devices) {
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
