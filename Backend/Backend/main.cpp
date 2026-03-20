// 遂沫 main.cpp
// 2026-03-21 02:09:38

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
#include "flutter_windows/cpp_client_wrapper/include/flutter/dart_project.h"

#include <stdpp/config.h>
#include <stdpp/encode.h>
#include <stdpp/exception.h>
#include <stdpp/util.h>

#include "flutter_windows/DartFFI.h"

#include "stdpp/SingletonRegistry.h"
#include "stdpp/screen.h"
#include "stdpp/compress.h"

#include "module/screenshot/screenshot.h"
#include "page/preveiw/preveiw.h"

#include "stdpp/file.h"
#include "stdpp/v8/js.h"
#include "stdpp/xorstr.h"
#include "stdpp/HotKey.h"

// 70cfbdc8f3b06f53663dfd8b17fb7218564c448032fe348da7abc2ab41e2dca06670cc2ef103d33a369e6d3dfa86f5884f3e3a36775d03a1a487822d33c75eb1

auto show_cert_msg(LONG v) -> void;
auto run(const std::string& info) -> int;

auto APIENTRY wWinMain(_In_ const HINSTANCE hInstance, _In_opt_ const HINSTANCE hPrevInstance, _In_ const LPWSTR lpCmdLine, _In_ const int nCmdShow) -> int try {
    using namespace stdpp::xorstr::literals;
    using namespace stdpp::v8;
    using namespace stdpp;

    [[maybe_unused]] auto _ = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    compress::Compressor::set<compress::IPP_LZ4Compressor>();

    init_engine();
    auto& js = JavaScript::current();

    #ifndef _DEBUG
    const auto local_file = file::app_path() / file::app_name(); const auto fingerprint = file::get_file_signature_fingerprint<64>(local_file, CALG_SHA_512); if (!fingerprint.has_value()) {
        show_cert_msg(fingerprint.error());
        return fingerprint.error();
    }

    // 自己发布改成你的代码签名哈希值
    // 非本人签名的文件造成的病毒传播、资料窃取等行为与本人无关，本人不对此承担任何责任
    if (!js.compile(
            R"(var str2 = "70cfbdc8f3b06f53663dfd8b17fb7218564c448032fe348da7abc2ab41e2dca06670cc2ef103d33a369e6d3dfa86f5884f3e3a36775d03a1a487822d33c75eb1";function check(str1){if(str1==str2){return run(str2);}return 114514;})"_xs)) {
        throw std::runtime_error("[v8Engine] JavaScript编译失败!"_xs);
    } js.bind("run"_xs, run); if (js.invoke<int>("check"_xs, util::bytes_to_hex_string(fingerprint.value())) == 114514) {
        CMSG(CLOG) << "[Verify] 校验未通过"_xs;
    }
    #else
    run(std::string(128, '\0'));
    #endif
    return EXIT_SUCCESS;
} catch (const std::exception& exception) {
    EMSG(ELOG) << exception.what();
    return EXIT_FAILURE;
} catch (const stdpp::exception::NativeException& exception) {
    EMSG(ELOG) << exception.what();
    return static_cast<int>(exception.code());
}

auto show_cert_msg(const LONG v) -> void {
    using namespace stdpp::xorstr::literals;
    switch (v) {
        case TRUST_E_NO_SIGNER_CERT: CMSG(CLOG) << "[CERT] 文件无签名, 请检查文件是否被修改"_xs;
            break;
        case TRUST_E_SUBJECT_NOT_TRUSTED: CMSG(CLOG) << "[CERT] 文件签名不被信任，可能使用了自签名证书或证书已被吊销"_xs;
            break;
        case TRUST_E_BAD_DIGEST: CMSG(CLOG) << "[CERT] 文件哈希验证失败，文件可能已被篡改"_xs;
            break;
        case TRUST_E_EXPLICIT_DISTRUST: CMSG(CLOG) << "[CERT] 文件签名已被明确标记为不受信任"_xs;
            break;
        case TRUST_E_SUBJECT_FORM_UNKNOWN: CMSG(CLOG) << "[CERT] 未知的文件格式，无法验证签名"_xs;
            break;
        case TRUST_E_PROVIDER_UNKNOWN: CMSG(CLOG) << "[CERT] 未知的签名提供程序"_xs;
            break;
        case TRUST_E_ACTION_UNKNOWN: CMSG(CLOG) << "[CERT] 未知的验证动作"_xs;
            break;
        case CERT_E_EXPIRED: CMSG(CLOG) << "[CERT] 签名证书已过期"_xs;
            break;
        case CERT_E_REVOKED: CMSG(CLOG) << "[CERT] 签名证书已被吊销"_xs;
            break;
        case CERT_E_UNTRUSTEDROOT: CMSG(CLOG) << "[CERT] 签名证书的根证书不受信任"_xs;
            break;
        case CERT_E_WRONG_USAGE: CMSG(CLOG) << "[CERT] 证书用途不正确"_xs;
            break;
        case CERT_E_CHAINING: CMSG(CLOG) << "[CERT] 证书链验证失败"_xs;
            break;
        case CRYPT_E_NO_MATCH: CMSG(CLOG) << "[CERT] 找不到匹配的签名"_xs;
            break;
        case CRYPT_E_NOT_FOUND: CMSG(CLOG) << "[CERT] 未找到签名信息"_xs;
            break;
        case CRYPT_E_NO_TRUSTED_SIGNER: CMSG(CLOG) << "[CERT] 没有受信任的签名者"_xs;
            break;
        case CRYPT_E_SIGNER_NOT_FOUND: CMSG(CLOG) << "[CERT] 找不到签名者"_xs;
            break;
        case CRYPT_E_HASH_VALUE: CMSG(CLOG) << "[CERT] 哈希值不匹配，文件可能已损坏"_xs;
            break;
        case TRUST_E_NOSIGNATURE: CMSG(CLOG) << "[CERT] 文件未签名, 请检查文件是否被修改"_xs;
            break;
        default: CMSG(CLOG) << "[CERT] 文件验证失败，错误码: 0x"_xs << std::hex << v << std::dec;
            break;
    }
}

auto run(const std::string& info) -> int try {
    using namespace stdpp::xorstr::literals;
    using namespace stdpp::v8;
    using namespace stdpp;

    if (info.size() != 128) {
        throw std::runtime_error("[JavaScript] 执行异常!"_xs);
    }

    singleton::SingletonController::init_call();
    hotkey::HotKey::init();
    if (!config::Config::load(file::app_path() / "cfg.toml"_xs)) {
        WLOG << "[Config] 加载配置文件失败!如果是第一次启动请忽略. 路径: "_xs << config::Config::config_path();
    }

    flutter::DartProject project(L"data"_xws);
    FlutterWindow window(project);
    Win32Window::Point origin(10, 10);
    Win32Window::Size size(1120, 680);

    if (!window.create(L"flutter_ui"_xws, origin, size)) {
        throw std::runtime_error("[flutter] 创建窗口失败!"_xs);
    }

    window.show(true);
    window.set_quit_on_close(true);
    window.msg_while([](const MSG& msg) {
        switch (msg.message) {
            case WM_QUIT: {
                module::Screenshot::stop_monitor();
                break;
            }
            case WM_DWMCOLORIZATIONCOLORCHANGED:
            case WM_SETTINGCHANGE: {
                break;
            }
            default:
                break;
        }
        return false;
    });

    hotkey::HotKey::shutdown();
    CoUninitialize();
    if (!config::Config::save()) {
        EMSG(ELOG) << "[Config] 保存配置文件失败! 路径: "_xs << config::Config::config_path();
    }
    return EXIT_SUCCESS;
} catch (const std::exception& exception) {
    CMSG(CLOG) << exception.what();
    return EXIT_FAILURE;
} catch (const stdpp::exception::NativeException& exception) {
    CMSG(CLOG) << exception.what();
    return static_cast<int>(exception.code());
}
