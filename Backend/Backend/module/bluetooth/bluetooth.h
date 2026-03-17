// 遂沫 bluetooth.h
// 2026-03-12 00:38:12

#pragma once
#include <stdpp/ble.h>

enum class MouseButton : uint8_t {
    BUTTON_NONE = 0x00,
    // 左键
    BUTTON_LEFT = 0x01,
    // 左键
    BUTTON_RIGHT = 0x02,
    // 右键
    BUTTON_MIDDLE = 0x04,
    // 中键
    BUTTON_BACK = 0x08,
    // 后退键
    BUTTON_FORWARD = 0x10 // 前进键
};

inline auto operator|(MouseButton a, MouseButton b) -> MouseButton {
    return static_cast<MouseButton>(static_cast<uint8_t>(a) | static_cast<uint8_t>(b));
}

inline auto operator&(MouseButton a, MouseButton b) -> MouseButton {
    return static_cast<MouseButton>(static_cast<uint8_t>(a) & static_cast<uint8_t>(b));
}

inline auto operator|=(MouseButton& a, const MouseButton b) -> MouseButton& {
    a = a | b;
    return a;
}

inline auto operator&=(MouseButton& a, const MouseButton b) -> MouseButton& {
    a = a & b;
    return a;
}

inline auto operator~(MouseButton a) -> MouseButton {
    return static_cast<MouseButton>(~static_cast<uint8_t>(a));
}

class MouseHID {
public:
    MouseHID() = delete;
    ~MouseHID() = delete;
    MouseHID(const MouseHID& other) = delete;
    MouseHID(MouseHID&& other) noexcept = delete;
    auto operator=(const MouseHID& other) -> MouseHID& = delete;
    auto operator=(MouseHID&& other) noexcept -> MouseHID& = delete;

    static auto clear() -> void;
    static auto connect(uint64_t addr) -> bool;
    static auto connect(const std::shared_ptr<stdpp::ble::Device>& device) -> bool;
    static auto connect(const std::shared_ptr<stdpp::ble::Device>& device, const std::shared_ptr<stdpp::ble::Service>& service, const std::shared_ptr<stdpp::ble::Characteristic>& characteristic) -> bool;

    static auto mouse_click(MouseButton button = MouseButton::BUTTON_NONE) -> bool;
    static auto mouse_press(MouseButton button) -> bool;
    static auto mouse_release(MouseButton button) -> bool;
    static auto mouse_move(int8_t x, int8_t y) -> bool;
    static auto mouse_wheel(int8_t v) -> bool;
private:
    struct alignas(1) MouseReport {
        MouseButton button;
        int8_t x;
        int8_t y;
        int8_t wheel;
    }inline static mouse_report;

    static auto send() -> bool;

    inline static std::shared_ptr<stdpp::ble::Device> device;
    inline static std::shared_ptr<stdpp::ble::Service> service;
    inline static std::shared_ptr<stdpp::ble::Characteristic> characteristic;
};
