// 遂沫 control.cpp
// 2026-03-07 20:02:21

#include "control.h"

#include "flutter_windows/DartFFI.h"

using namespace page;
using namespace flutter;

ControlPage::ControlPage() {
    SingletonRegistry::touch();
}

auto ControlPage::singleton_init() -> void {
    Dart::field(speed);
    Dart::field(keys);
    Dart::field(device);
    Dart::field(auto_fire);

    keys.add_event([](const std::shared_ptr<FieldEntryBase>& field_entry_base, const Event event) {
        const auto ptr = instance();
        int key_bit{0};
        for (auto& key : *ptr->keys) {
            key_bit |= key;
        }
        ptr->key = key_bit;
    });
}
