// 遂沫 Backend.cpp
// 2026-02-18 23:18:35

#pragma comment(lib, "ntdll.lib")
// ReSharper disable CppUnusedIncludeDirective
// ReSharper disable CppWrongIncludesOrder
#include <mimalloc/mimalloc.h>
#include <new>
#include <vector>
#include <future>
#include <iostream>
#include <thread>
#include <random>
#include <chrono>
#include <cassert>
#include <mimalloc/mimalloc-new-delete.h>
#include <windows.h>

#include <flutter_windows/flutter_window.h>
#include <flutter_windows/win32_window.h>
#include <stdpp/config.h>
#include <stdpp/encode.h>
#include <stdpp/exception.h>
#include <stdpp/util.h>
#include "flutter_windows/cpp_client_wrapper/include/flutter/dart_project.h"

auto APIENTRY wWinMain(_In_ const HINSTANCE hInstance, _In_opt_ const HINSTANCE hPrevInstance, _In_ const LPWSTR lpCmdLine, _In_ const int nCmdShow) -> int try {
    [[maybe_unused]] auto _ = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

    if (!stdpp::config::Config::load(stdpp::util::app_path() / "cfg.toml")) {
        WLOG << "加载配置文件失败!如果是第一次启动请忽略.";
    }

    flutter::DartProject project(L"data");
    FlutterWindow window(project);
    Win32Window::Point origin(10, 10);
    Win32Window::Size size(1120, 680);

    if (!window.create(L"flutter_ui", origin, size)) {
        return EXIT_FAILURE;
    }

    window.show(true);
    window.set_quit_on_close(true);
    window.msg_while();

    CoUninitialize();
    return EXIT_SUCCESS;
} catch (const std::exception& exception) {
    MessageBox(nullptr, stdpp::encode::char_to_wchar(exception.what()).data(), L"致命错误", 0);
    return EXIT_FAILURE;
} catch (const stdpp::exception::NativeException& exception) {
    MessageBox(nullptr, stdpp::encode::char_to_wchar(exception.what()).data(), L"致命错误", 0);
    return exception.code();
}
