// 遂沫 backend.cpp
// 2026-02-23 21:10:41

#include "backend.h"
#include <magic_enum/magic_enum.hpp>

#include "flutter_windows/DartFFI.h"

#include "module/ModelBackend.h"

using namespace page;
using namespace flutter;

BackendPage::BackendPage() {
    SingletonRegistry::touch();
}

auto BackendPage::singleton_init() -> void {
    Dart::field(backend_name);
    Dart::field(device_name);

    backend_name.add_event([](const std::shared_ptr<FieldEntryBase>& field_entry_base, const Event event) {
        module::ModelBackendManager::select(*instance()->backend_name);
    });

    device_name.add_event([](const std::shared_ptr<FieldEntryBase>& field_entry_base, const Event event) {
        module::ModelBackendManager::set_device(*instance()->device_name);
    });

    "get_backends"_dart.method([](DartFFI::ValueMapArgs& pairs, const DartFFI::Result& method_result) {
        EncodableList list;
        for (auto& name : module::ModelBackendManager::get_backends()) {
            TLOG << name;
            list.emplace_back(Value(name));
        }
        method_result->success(Value(list));
    });

    "get_devices"_dart.method([](DartFFI::ValueMapArgs& pairs, const DartFFI::Result& method_result) {
        ValueList list;
        for (auto& [type, device] : module::ModelBackendManager::get_devices()) {
            list.push_back(Value(device));
            TLOG << "(" << magic_enum::enum_name(type).data() << ") " << device;
        }
        method_result->success(Value(list));
    });
}
