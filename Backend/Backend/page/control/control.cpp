// 遂沫 control.cpp
// 2026-03-21 03:13:54

#include "control.h"
#include "flutter_windows/DartFFI.h"
#include "module/bluetooth/bluetooth.h"
#include "stdpp/HotKey.h"
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
    toggle_auto_fire = Dart::field(auto_fire);
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
        UINT modifiers = 0;
        UINT vk = 0;
        for (auto& key : *ptr->auto_fire_hot_key) {
            switch (key) {
                case VK_CONTROL:
                case VK_LCONTROL:
                case VK_RCONTROL:
                    modifiers |= MOD_CONTROL;
                    break;
                case VK_MENU:
                case VK_LMENU:
                case VK_RMENU:
                    modifiers |= MOD_ALT;
                    break;
                case VK_SHIFT:
                case VK_LSHIFT:
                case VK_RSHIFT:
                    modifiers |= MOD_SHIFT;
                    break;
                case VK_LWIN:
                case VK_RWIN:
                    modifiers |= MOD_WIN;
                    break;
                default:
                    vk = key;
                    break;
            }
        }
        ptr->auto_fire_key = vk;
        if (ptr->key_id) {
            stdpp::hotkey::HotKey::unregister(ptr->key_id);
        }
        if (vk != 0) {
            ptr->key_id = stdpp::hotkey::HotKey::register_key(modifiers,
                                                              vk,
                                                              [ptr] {
                                                                  ptr->toggle_auto_fire(!ptr->auto_fire);
                                                              });
        }
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
