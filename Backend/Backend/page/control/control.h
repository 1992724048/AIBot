// 遂沫 control.h
// 2026-03-07 18:40:41

#pragma once

#include <stdpp/config.h>

#include "module/ModelBackend.h"

#include "stdpp/SingletonRegistry.h"

namespace page {
    using namespace stdpp::config;
    using namespace stdpp::singleton;

    class ControlPage final : public SingletonRegistry<ControlPage> {
    public:
        ControlPage();
        ~ControlPage() override = default;

        std::atomic_int key;

        Field<std::vector<int32_t>> keys{"ControlPage::keys", {VK_LSHIFT}};
        Field<float> speed{"ControlPage::speed", 1};
        Field<std::string> device{"ControlPage::device", "WindowsAPI"};
        Field<bool> auto_fire{"ControlPage::auto_fire", false};

        auto singleton_init() -> void override;
    };
} // namespace page
