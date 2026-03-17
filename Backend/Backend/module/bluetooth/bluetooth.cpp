// 遂沫 bluetooth.cpp
// 2026-03-12 00:38:28

#include "bluetooth.h"

auto MouseHID::clear() -> void {
    device = nullptr;
    service = nullptr;
    characteristic = nullptr;
}

auto MouseHID::connect(const uint64_t addr) -> bool {
    service = nullptr;
    characteristic = nullptr;
    if (!stdpp::ble::Bluetooth::is_low_energy_supported()) {
        return false;
    }

    const auto device_result = stdpp::ble::Bluetooth::connect(addr);
    if (!device_result) {
        return false;
    }

    device = device_result.value();
    const auto service_result = device->get_service(0x00A0);
    if (!service_result) {
        return false;
    }

    service = service_result.value();
    const auto char_result = service->get_characteristic(0x0001);
    if (!char_result) {
        return false;
    }

    characteristic = char_result.value();
    return true;
}

auto MouseHID::connect(const std::shared_ptr<stdpp::ble::Device>& device) -> bool {
    MouseHID::device = device;
    service = nullptr;
    characteristic = nullptr;
    const auto service_result = device->get_service(0x00A0);
    if (!service_result) {
        return false;
    }

    service = service_result.value();
    const auto char_result = service->get_characteristic(0x0001);
    if (!char_result) {
        return false;
    }

    characteristic = char_result.value();
    return true;
}

auto MouseHID::connect(const std::shared_ptr<stdpp::ble::Device>& device,
                       const std::shared_ptr<stdpp::ble::Service>& service,
                       const std::shared_ptr<stdpp::ble::Characteristic>& characteristic) -> bool {
    MouseHID::device = device;
    MouseHID::service = service;
    MouseHID::characteristic = characteristic;
    return true;
}

auto MouseHID::mouse_click(const MouseButton button) -> bool {
    mouse_press(button);
    mouse_release(button);
    return true;
}

auto MouseHID::mouse_press(const MouseButton button) -> bool {
    mouse_report.button |= button;
    return send();
}

auto MouseHID::mouse_release(const MouseButton button) -> bool {
    mouse_report.button &= ~button;
    return send();
}

auto MouseHID::mouse_move(const int8_t x, const int8_t y) -> bool {
    mouse_report.x = x;
    mouse_report.y = y;
    const bool result = send();
    mouse_report.x = 0;
    mouse_report.y = 0;
    return result;
}

auto MouseHID::mouse_wheel(const int8_t v) -> bool {
    mouse_report.wheel = v;
    const bool result = send();
    mouse_report.wheel = 0;
    return result;
}

auto MouseHID::send() -> bool {
    if (!characteristic) {
        return false;
    }
    const auto result = characteristic->write(mouse_report);
    return result.get().Status() == winrt::Windows::Devices::Bluetooth::GenericAttributeProfile::GattCommunicationStatus::Success;
}
