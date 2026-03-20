// 遂沫 control.h
// 2026-03-11 16:01:36

#pragma once

#include <stdpp/config.h>
#include "module/ModelBackend.h"
#include "stdpp/SingletonRegistry.h"

namespace page {
    using namespace stdpp::config;
    using namespace stdpp::singleton;

    enum DeviceModeEnum : int { WindowsAPI, ESP32S3BLE };

    class ControlPage final : public SingletonRegistry<ControlPage> {
    public:
        ControlPage();
        ~ControlPage() override = default;

        std::atomic_int key;
        std::atomic_int auto_fire_key;
        std::atomic_int key_id;

        std::function<void(std::optional<bool>)> toggle_auto_fire;

        Field<std::vector<int32_t>> keys{"ControlPage::keys", {VK_LSHIFT}};
        Field<std::vector<int32_t>> auto_fire_hot_key{"ControlPage::auto_fire_hot_key", {VK_XBUTTON1}};
        Field<float> speed{"ControlPage::speed", 1};
        Field<float> x{"ControlPage::x", 50};
        Field<float> y{"ControlPage::y", 20};
        Field<DeviceModeEnum> device{"ControlPage::device", WindowsAPI};
        Field<bool> auto_fire{"ControlPage::auto_fire", false};

        auto singleton_init() -> void override;
    };
} // namespace page
