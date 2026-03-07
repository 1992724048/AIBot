// 遂沫 model.cpp
// 2026-03-03 18:23:08

#include "model.h"
#include "flutter_windows/DartFFI.h"

#include "module/ModelBackend.h"

#include "stdpp/file.h"

#include "toml11/toml.hpp"

using namespace page;
using namespace flutter;
using namespace stdpp;

ModelPage::ModelPage() {
    SingletonRegistry::touch();
}

auto ModelPage::get_tag_name(const int id) const -> std::string {
    const auto ptr = current.load();
    std::shared_lock _(ptr->mutex);
    if (ptr->tag.contains(id)) {
        return ptr->tag_name[id];
    }
    return {};
}

auto ModelPage::singleton_init() -> void {
    Dart::field(model_name);

    model_name.add_event([](const std::shared_ptr<FieldEntryBase>& field_entry_base, const Event event) {
        if (event == Event::VALUE_CHANG) {
            const auto ins = instance();
            if (!ins->model_map.contains(*ins->model_name)) {
                return;
            }

            std::unique_lock _(ins->mutex);
            ins->current = ins->model_map[*ins->model_name];
            module::ModelBackendManager::load(ins->current.load());
        }
        if (event == Event::VALUE_LOAD) {}
    });

    "get_models"_dart.method([this](DartFFI::ValueMapArgs& pairs, const DartFFI::Result& method_result) {
        model_map.clear();
        EncodableList list;

        if (!is_directory(model_dir)) {
            create_directory(model_dir);
            return method_result->success(Value(list));
        }

        bool find_select{false};
        for (std::filesystem::path& path : file::get_subdirectories(model_dir)) {
            auto model_path = model_dir / path;
            if (!exists(model_path / "model.toml")) {
                continue;
            }

            auto toml_cfg = toml::parse(model_path / "model.toml");
            if (!toml_cfg.contains("model") || !toml_cfg.contains("tag")) {
                continue;
            }

            auto& model_cfg = toml_cfg["model"];
            auto& tag_cfg = toml_cfg["tag"];
            if (!model_cfg.contains("name") || !model_cfg.contains("file") || !model_cfg.contains("backend") || !model_cfg.contains("type")) {
                continue;
            }

            if (!tag_cfg.contains("names")) {
                continue;
            }

            auto _ = model_name.read_lock();
            auto name = model_cfg["name"].as_string();
            std::string backend = model_cfg["backend"].as_string();
            std::string type = model_cfg["type"].as_string();
            std::string file = model_cfg["file"].as_string();
            auto& tags = tag_cfg["names"].as_array();

            if (name == *model_name) {
                find_select = true;
            }

            std::vector<std::string> parts;
            for (const auto& part : backend | std::views::split(':')) {
                parts.emplace_back(part.begin(), part.end());
            }

            std::string backend_name;
            std::string precision;
            if (parts.size() == 2) {
                backend_name = parts[0];
                precision = parts[1];
            } else {
                continue;
            }

            auto _ = select_tag.write_lock();
            int id{0};
            EncodableMap tag_map;
            phmap::flat_hash_map<int, bool> tag_id;
            phmap::flat_hash_map<int, std::string> tag_id_name;
            for (auto& tag : tags) {
                auto current_id = id++;
                tag_id[current_id] = false;
                tag_id_name[current_id] = tag.as_string();
                tag_map[Value(current_id)] = Value(tag.as_string());
                auto& ids = select_tag.value()[name];
                if (!ids.contains(current_id)) {
                    ids[current_id] = false;
                }
            }
            select_tag.chang(true);

            EncodableMap map;
            map[Value("name")] = Value(name);
            map[Value("backend")] = Value(backend);
            map[Value("tag_map")] = Value(tag_map);
            list.emplace_back(map);

            DLOG << "Model name: " << name << " Backend name: " << backend_name;

            auto& ptr = model_map[name] = std::make_shared<ModelInfo>();
            ptr->name = name;
            ptr->path = model_path / file;
            ptr->ptq = precision;
            ptr->backend_name = backend_name;
            ptr->type = type;
            ptr->tag = tag_id;
            ptr->tag_name = tag_id_name;
        }

        if (!find_select) {
            auto _ = model_name.write_lock();
            model_name.value().clear();
            model_name.chang(true);
        } else {
            auto _ = model_name.read_lock();
            std::unique_lock _(mutex);
            current = model_map[*model_name];
            module::ModelBackendManager::load(current.load());
        }

        auto _ = select_tag.write_lock();
        if (std::erase_if(select_tag.value(),
                          [this](const auto& item) {
                              const auto& [key, value] = item;
                              return !model_map.contains(key);
                          })) {
            select_tag.chang(true);
        }

        method_result->success(Value(list));
    });

    "set_tag"_dart.method([this](DartFFI::ValueMapArgs& pairs, const DartFFI::Result& method_result) {
        const auto name = std::get<std::string>(pairs["name"]);
        const int id = std::get<int>(pairs["tag"]);
        const bool select = std::get<bool>(pairs["select"]);

        auto _ = select_tag.write_lock();
        select_tag.value()[name][id] = select;
        select_tag.chang(true);

        const auto ptr = current.load();
        std::unique_lock _(ptr->mutex);
        ptr->tag[id] = select;
        method_result->success();
    });

    "get_tag"_dart.method([this](DartFFI::ValueMapArgs& pairs, const DartFFI::Result& method_result) {
        const auto name = std::get<std::string>(pairs["name"]);
        auto _ = select_tag.read_lock();
        EncodableMap map;
        for (auto& [id, select] : select_tag.value()[name]) {
            map[Value(id)] = Value(select);
        }

        if (const auto ptr = current.load()) {
            std::unique_lock _(ptr->mutex);
            for (auto& [id, select] : select_tag.value()[name]) {
                ptr->tag[id] = select;
            }
        }

        method_result->success(Value(map));
    });
}
