// 遂沫 backend.h
// 2026-02-22 18:40:19

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

        Field<std::string> backend_name{"backend_name", ""};
        Field<std::string> device_name{"device_name", ""};

        auto singleton_init() -> void override;
    };
} // namespace page
