// 遂沫 control.cpp
// 2026-03-13 16:38:12

#include "control.h"
#include "flutter_windows/DartFFI.h"

#include "module/bluetooth/bluetooth.h"

#include "stdpp/ble.h"

using namespace page;
using namespace flutter;
using namespace std::chrono_literals;

ControlPage::ControlPage() {
    SingletonRegistry::touch();
}

auto ControlPage::singleton_init() -> void {
    Dart::field(speed);
    Dart::field(x);
    Dart::field(y);
    Dart::field(keys);
    Dart::field(device);
    Dart::field(auto_fire);
    Dart::field(auto_fire_hot_key);

    keys.add_event([](const std::shared_ptr<FieldEntryBase>& field_entry_base, const Event event) {
        const auto ptr = instance();
        int key_bit{0};
        for (auto& key : *ptr->keys) {
            key_bit |= key;
        }
        ptr->key = key_bit;
    });

    auto_fire_hot_key.add_event([](const std::shared_ptr<FieldEntryBase>& field_entry_base, const Event event) {
        const auto ptr = instance();
        int key_bit{0};
        for (auto& key : *ptr->keys) {
            key_bit |= key;
        }
        ptr->auto_fire_key = key_bit;
    });

    "get_ble_device"_dart.method([](std::map<std::string, EncodableValue>& pairs, const std::unique_ptr<MethodResult<>>& method_result) {
        ValueMap map;

        MouseHID::clear();
        for (const auto& device : stdpp::ble::Bluetooth::get_devices()) {
            if (auto service = device->get_service(0x1145)) {
                if (auto char_ = (*service)->get_characteristic(0x0001)) {
                    DLOG << "已选择蓝牙设备名称: " << stdpp::encode::wchar_to_char(device->name());
                    map[Value("addr")] = Value(static_cast<int64_t>(device->address()));
                    map[Value("name")] = Value(stdpp::encode::wchar_to_char(device->name()));
                    map[Value("status")] = Value(MouseHID::connect(device));
                }
            }
        }

        method_result->success(Value(map));
    });
}
