// 遂沫 openvino.h
// 2026-02-22 18:39:03

#pragma once
#include <openvino/openvino.hpp>
#include "module/ModelBackend.h"

namespace module {
    class OpenVINOImpl final : public ModelBackendAbstract, BackendRegistry<OpenVINOImpl> {
    public:
        inline static const auto BackendName = "OpenVINO";

        OpenVINOImpl();
        ~OpenVINOImpl() override = default;

        auto load(const std::filesystem::path& path) -> bool override;
        auto infer(const cv::Mat& frame) -> std::optional<std::vector<cv::Size>> override;
        auto set_device(const std::string& device_name) -> void override;
        auto get_devices() -> std::vector<DeviceInfo> override;
    private:
        ov::Core core;
        ov::CompiledModel compiled_model;
        ov::InferRequest inference_request;
        std::shared_ptr<ov::Model> model;
    };
} // namespace module
