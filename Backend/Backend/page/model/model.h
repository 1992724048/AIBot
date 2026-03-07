// 遂沫 model.h
// 2026-02-27 01:37:30

#pragma once

#include <map>
#include <stdpp/config.h>

#include "stdpp/SingletonRegistry.h"
#include "stdpp/file.h"

namespace page {
    using namespace stdpp::config;
    using namespace stdpp::singleton;

    struct ModelInfo {
        std::shared_mutex mutex;
        std::filesystem::path path;
        std::string name;
        std::string backend_name;
        std::string ptq;
        std::string type;
        phmap::flat_hash_map<int, bool> tag;
        phmap::flat_hash_map<int, std::string> tag_name;
    };

    class ModelPage final : public SingletonRegistry<ModelPage> {
    public:
        ModelPage();
        ~ModelPage() override = default;

        Field<std::string> model_name{"ModelPage::model_name", ""};
        Field<std::map<std::string, std::map<int, bool>>> select_tag{"ModelPage::select_tag", {}};

        auto get_tag_name(int id) const -> std::string;
        auto is_select(int id) const -> bool;

        auto singleton_init() -> void override;
    private:
        const std::filesystem::path model_dir = stdpp::file::app_path() / "model";

        std::shared_mutex mutex;
        std::atomic<std::shared_ptr<ModelInfo>> current;
        phmap::flat_hash_map<std::string, std::shared_ptr<ModelInfo>> model_map;
    };
} // namespace page
