// 遂沫 control.h
// 2026-03-02 22:30:33

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

        Field<std::vector<int32_t>> keys{"ControlPage::keys", {VK_LSHIFT}};
        Field<float> speed{"ControlPage::speed", 0.5};

        auto singleton_init() -> void override;
    };
} // namespace page
