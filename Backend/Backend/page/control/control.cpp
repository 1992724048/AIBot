// 遂沫 control.cpp
// 2026-03-02 18:17:14

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
}
