// 遂沫 ModelBackend.h
// 2026-02-22 21:50:27

#pragma once
#include <atomic>
#include <filesystem>
#include <memory>
#include <optional>

#include <opencv2/opencv.hpp>

namespace module {
    enum class BackendDeviceEnum : int { CPU, GPU, NPU };

    struct DeviceInfo {
        BackendDeviceEnum type;
        std::string name;
    };

    /**
     * @brief 后端接口抽象类
     */
    class ModelBackendAbstract {
    public:
        ModelBackendAbstract() = default;
        virtual ~ModelBackendAbstract() = default;

        virtual auto set_device(const std::string& device_name) -> void = 0;
        virtual auto get_devices() -> std::vector<DeviceInfo> = 0;
        virtual auto load(const std::filesystem::path& path) -> bool = 0;
        virtual auto infer(const cv::Mat& frame) -> std::optional<std::vector<cv::Size>> = 0;

        ModelBackendAbstract(const ModelBackendAbstract& other) = delete;
        ModelBackendAbstract(ModelBackendAbstract&& other) noexcept = delete;
        auto operator=(const ModelBackendAbstract& other) -> ModelBackendAbstract& = delete;
        auto operator=(ModelBackendAbstract&& other) noexcept -> ModelBackendAbstract& = delete;
    };

    /**
     * @brief 后端管理类
     */
    class ModelBackendManager {
    public:
        ModelBackendManager(const ModelBackendManager& other) = delete;
        ModelBackendManager(ModelBackendManager&& other) noexcept = delete;
        auto operator=(const ModelBackendManager& other) -> ModelBackendManager& = delete;
        auto operator=(ModelBackendManager&& other) noexcept -> ModelBackendManager& = delete;

        template<typename T>
        static auto set_backend() -> void {
            current = std::make_shared<T>();
        }

        static auto load(const std::filesystem::path& path) -> bool;
        static auto infer(const cv::Mat& frame) -> std::optional<std::vector<cv::Size>>;
        static auto set_device(const std::string& device_name) -> bool;
        static auto get_devices() -> std::vector<DeviceInfo>;
        static auto select(const std::string& name) -> bool;
        static auto get_backends() -> std::vector<std::string>;
    protected:
        inline static cv::Size input_size;
        inline static cv::Size output_size;
        inline static cv::Point2f scale_factor;
        inline static std::filesystem::path current_path;
        inline static std::atomic<std::shared_ptr<ModelBackendAbstract>> current;
        inline static std::map<std::string, std::function<void()>> select_fn;

        friend ModelBackendAbstract;
        ModelBackendManager() = default;
        ~ModelBackendManager() = default;
    };

    /**
     * @brief 自动将后端添加到管理类里
     * @tparam T 类型模板
     * @tparam AutoCreation 自动注册(默认即可)
     */
    template<typename T, bool AutoCreation = true>
    class BackendRegistry : ModelBackendManager {
    public:
        BackendRegistry() {
            BackendRegistry::touch();
        }

        virtual ~BackendRegistry() = default;

        BackendRegistry(const BackendRegistry& other) = delete;
        BackendRegistry(BackendRegistry&& other) noexcept = delete;
        auto operator=(const BackendRegistry& other) -> BackendRegistry& = delete;
        auto operator=(BackendRegistry&& other) noexcept -> BackendRegistry& = delete;
    protected:
        struct Registry {
            Registry() {
                if (AutoCreation) {
                    select_fn[T::BackendName] = push;
                }
            }
        };

        virtual auto touch() -> Registry* {
            return &registry;
        }

        static Registry registry;
        friend T;
    private:
        static auto push() -> void {
            ModelBackendManager::set_backend<T>();
        }
    };
} // namespace module

template<typename T, bool AutoCreation>
inline module::BackendRegistry<T, AutoCreation>::Registry module::BackendRegistry<T, AutoCreation>::registry;
