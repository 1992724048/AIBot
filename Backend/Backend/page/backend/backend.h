// 遂沫 backend.h
// 2026-02-24 17:35:11

#pragma once

#include <stdpp/config.h>
#include "stdpp/SingletonRegistry.h"

namespace page {
    using namespace stdpp::config;
    using namespace stdpp::singleton;

    class BackendPage final : public SingletonRegistry<BackendPage> {
    public:
        BackendPage();
        ~BackendPage() override = default;

        Field<std::string> backend_name{"BackendPage::backend_name", ""};
        Field<std::string> device_name{"BackendPage::device_name", ""};
        Field<float> nms{"BackendPage::nms", 0.5};
        Field<float> confidence{"BackendPage::confidence", 0.5};

        auto singleton_init() -> void override;
    };
} // namespace page
