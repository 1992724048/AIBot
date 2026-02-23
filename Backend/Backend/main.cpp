// 遂沫 main.cpp
// 2026-02-22 16:11:31

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
#include <print>

#include <flutter_windows/flutter_window.h>
#include <flutter_windows/win32_window.h>
#include <stdpp/config.h>
#include <stdpp/encode.h>
#include <stdpp/exception.h>
#include <stdpp/util.h>
#include "flutter_windows/cpp_client_wrapper/include/flutter/dart_project.h"

#include "module/screenshot/screenshot.h"

#include "stdpp/SingletonRegistry.h"
#include "page/preveiw/preveiw.h"

#include "stdpp/screen.h"
#include "stdpp/compress.h"

auto APIENTRY wWinMain(_In_ const HINSTANCE hInstance, _In_opt_ const HINSTANCE hPrevInstance, _In_ const LPWSTR lpCmdLine, _In_ const int nCmdShow) -> int try {
    [[maybe_unused]] auto _ = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    stdpp::compress::Compressor::set<stdpp::compress::IPP_LZ4Compressor>();
    stdpp::singleton::SingletonController::init_call();
    if (!stdpp::config::Config::load(stdpp::util::app_path() / "cfg.toml")) {
        WLOG << "加载配置文件失败!如果是第一次启动请忽略. 路径: " << stdpp::config::Config::config_path();
    }

    stdpp::exception::set_callback([](PEXCEPTION_POINTERS) {
        stdpp::config::Config::save();
    });

    flutter::DartProject project(L"data");
    FlutterWindow window(project);
    Win32Window::Point origin(10, 10);
    Win32Window::Size size(1120, 680);

    if (!window.create(L"flutter_ui", origin, size)) {
        EMSG(ELOG) << "[flutter] 创建窗口失败!";
        return EXIT_FAILURE;
    }

    window.show(true);
    window.set_quit_on_close(true);
    window.msg_while([](const MSG& msg) {
        if (msg.message == WM_QUIT) {
            module::Screenshot::stop_monitor();
        }
        return false;
    });

    CoUninitialize();
    if (!stdpp::config::Config::save()) {
        WMSG(WLOG) << "保存配置文件失败! 路径: " << stdpp::config::Config::config_path();
    }

    return EXIT_SUCCESS;
} catch (const std::exception& exception) {
    MessageBox(nullptr, stdpp::encode::char_to_wchar(exception.what()).data(), L"致命错误", MB_OK | MB_ICONERROR);
    return EXIT_FAILURE;
} catch (const stdpp::exception::NativeException& exception) {
    MessageBox(nullptr, stdpp::encode::char_to_wchar(exception.what()).data(), L"致命错误", MB_OK | MB_ICONERROR);
    return exception.code();
}
