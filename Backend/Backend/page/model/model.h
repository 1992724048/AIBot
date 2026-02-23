// 遂沫 model.h
// 2026-02-22 17:55:37

#pragma once

#include <stdpp/config.h>
#include "stdpp/SingletonRegistry.h"

namespace page {
    using namespace stdpp::config;
    using namespace stdpp::singleton;

    class ModelPage final : public SingletonRegistry<ModelPage> {
    public:
        ModelPage() = default;
        ~ModelPage() override = default;

        auto singleton_init() -> void override;
    };
} // namespace page
