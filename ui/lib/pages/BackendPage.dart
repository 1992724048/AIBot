import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:ui/widget/AlertBlock.dart';
import 'package:ui/widget/AsyncDropdown.dart';
import 'package:ui/widget/AsyncStringInput.dart';
import 'package:ui/widget/AsyncSwitch.dart';
import 'package:ui/widget/CustomCard.dart';
import 'package:ui/widget/SmoothScrollView.dart';

class BackendPage extends StatefulWidget {
  const BackendPage({super.key});

  @override
  State<BackendPage> createState() => _BackendPageState();
}

class Device {
  String type;
  List<String> name;

  Device({required this.type, required this.name});
}

class Backend {
  String name;
  List<Device> devices;
  bool multiDevice = false;
  bool autoDevice = false;

  Backend({required this.name, required this.devices, this.multiDevice = false, this.autoDevice = false});
}

class SYCLDevice {
  String name;
  String type;

  SYCLDevice(this.name, this.type);
}

class _BackendPageState extends State<BackendPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final List<Backend> _availableBackends = [
    Backend(
      name: 'OpenVINO',
      devices: [
        Device(type: 'CPU', name: ['Intel Core i5', 'Intel Core i7']),
        Device(type: 'GPU', name: ['Intel Iris Xe', 'Intel UHD Graphics']),
        Device(type: 'NPU', name: ['Intel Movidius Myriad X', 'Intel Neural Compute Stick 2']),
      ],
      multiDevice: true,
      autoDevice: true,
    ),
  ];

  late String _selectedBackend = _availableBackends.first.name;
  late String _selectedDeviceType = _availableBackends.first.devices.first.type;
  late String _selectedDeviceName = _availableBackends.first.devices.first.name.first;
  late bool _multiDevice = _availableBackends.first.multiDevice;
  late bool _autoDevice = _availableBackends.first.autoDevice;
  late bool _autoDeviceEnabled = false;
  late bool _multiDeviceEnabled = false;
  bool _enableSYCL = false;
  bool _enableMultiThread = false;
  bool _disableMultiThread = false;
  bool _disableSYCL = false;
  List<SYCLDevice> syclDevices = [
    SYCLDevice("Intel(R) UHD Graphics 750", "GPU"),
    SYCLDevice("NVIDIA GeForce RTX 3060 Laptop GPU", "GPU"),
    SYCLDevice("Intel(R) Core(TM) i7-11800H CPU @ 2.30GHz", "CPU"),
  ];
  late String selectedSYCLDeviceType = syclDevices.first.type;
  late String selectedSYCLDevice = syclDevices.first.name;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SmoothScrollView(
      scrollSpeed: 2,
      damping: 0.25,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const double minCardWidth = 700;
            const double spacing = 10;

            final int crossAxisCount = math.max(1, (constraints.maxWidth / (minCardWidth + spacing)).ceil());
            final double cardWidth = (constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;

            return MasonryGridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              itemCount: 5,
              itemBuilder: (context, index) {
                return switch (index) {
                  0 => SizedBox(width: cardWidth, child: _SelectBackend()),
                  1 => SizedBox(width: cardWidth, child: _ResultProcess()),
                  _ => const SizedBox(),
                };
              },
            );
          },
        ),
      ),
    );
  }

  Widget _BuildDeviceTypeDropdown() {
    return Column(
      children: [
        AsyncDropdown(
          key: ValueKey('deviceType:$_selectedBackend'),
          label: '设备类型',
          items: () async {
            await Future.delayed(const Duration(milliseconds: 500));
            final backend = _availableBackends.firstWhere(
              (b) => b.name == _selectedBackend,
              orElse: () => Backend(name: '', devices: []),
            );
            return backend.devices.map((d) => d.type).toList();
          },
          onChanged: (value) async {
            await Future.delayed(const Duration(milliseconds: 500));
            final backend = _availableBackends.firstWhere(
              (b) => b.name == _selectedBackend,
              orElse: () => Backend(name: '', devices: []),
            );
            final device = backend.devices.firstWhere(
              (d) => d.type == value,
              orElse: () => Device(type: '', name: []),
            );
            final newDeviceName = device.name.isNotEmpty ? device.name.first : '';
            setState(() {
              _selectedDeviceType = value;
              _selectedDeviceName = newDeviceName;
            });
            return true;
          },
          value: _selectedDeviceType,
        ),
        const SizedBox(height: 10),
        AsyncDropdown(
          key: ValueKey('deviceName:$_selectedBackend:$_selectedDeviceType'),
          label: '设备名称',
          items: () async {
            await Future.delayed(const Duration(milliseconds: 500));
            final backend = _availableBackends.firstWhere(
              (b) => b.name == _selectedBackend,
              orElse: () => Backend(name: '', devices: []),
            );
            final device = backend.devices.firstWhere(
              (d) => d.type == _selectedDeviceType,
              orElse: () => Device(type: '', name: []),
            );
            return device.name;
          },
          onChanged: (value) async {
            await Future.delayed(const Duration(milliseconds: 500));
            setState(() {
              _selectedDeviceName = value;
            });
            return true;
          },
          value: _selectedDeviceName,
        ),
      ],
    );
  }

  Widget _BuildDeviceSwitch() {
    return Column(
      children: [
        SizedBox(height: 8),
        AsyncSwitch(
          title: Text('自动选择设备'),
          selected: false,
          defaultSelected: false,
          onSelected: (value) async {
            setState(() {
              _multiDevice = !value;
            });
            await Future.delayed(const Duration(milliseconds: 500));
            setState(() {
              _autoDeviceEnabled = value;
            });
            return true;
          },
          subtitle: const Text('后端将根据当前硬件环境自动选择设备 (可能选择非最佳硬件)', style: TextStyle(fontSize: 12)),
          enabled: _autoDevice && !_multiDeviceEnabled,
        ),
        SizedBox(height: 8),
        AsyncSwitch(
          title: Text('选择多个设备'),
          selected: false,
          defaultSelected: false,
          onSelected: (value) async {
            setState(() {
              _autoDevice = !value;
            });
            await Future.delayed(const Duration(milliseconds: 500));
            setState(() {
              _multiDeviceEnabled = value;
            });
            return true;
          },
          subtitle: const Text('选择多个推理设备进行推理计算 (设备支持的精度需要相同)', style: TextStyle(fontSize: 12)),
          enabled: _multiDevice && !_autoDeviceEnabled,
        ),
      ],
    );
  }
  
  Widget _SelectBackend() {
    return CustomCard(
      title: Baseline(
        baseline: 14,
        baselineType: TextBaseline.alphabetic,
        child: Text('推理后端', style: TextStyle(fontSize: 14, height: 1.0)),
      ),
      icon: Icons.storage,
      elevation: 2,
      child: SizedBox(
        child: Column(
          children: [
            AsyncDropdown(
              label: '后端框架',
              items: () async {
                await Future.delayed(const Duration(milliseconds: 500));
                return _availableBackends.map((b) => b.name).toList();
              },
              onChanged: (value) async {
                await Future.delayed(const Duration(milliseconds: 500));
                final newBackend = _availableBackends.firstWhere(
                  (b) => b.name == value,
                  orElse: () => Backend(name: '', devices: []),
                );
                final newDeviceType = newBackend.devices.isNotEmpty ? newBackend.devices.first.type : '';
                final newDeviceName = newBackend.devices.isNotEmpty && newBackend.devices.first.name.isNotEmpty
                    ? newBackend.devices.first.name.first
                    : '';
                setState(() {
                  _selectedBackend = value;
                  _selectedDeviceType = newDeviceType;
                  _selectedDeviceName = newDeviceName;
                  _multiDevice = newBackend.multiDevice;
                  _autoDevice = newBackend.autoDevice;
                });
                return true;
              },
              value: _selectedBackend,
            ),
            Divider(thickness: 1),
            AlertBlock.note(child: Text('由 $_selectedBackend 提供支持的设备选项')),
            _BuildDeviceSwitch(),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: _autoDeviceEnabled
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        Divider(thickness: 1),
                        _multiDeviceEnabled ? SizedBox.shrink() : _BuildDeviceTypeDropdown(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ResultProcess() {
    return CustomCard(
      title: Baseline(
        baseline: 14,
        baselineType: TextBaseline.alphabetic,
        child: Text('结果处理', style: TextStyle(fontSize: 14, height: 1.0)),
      ),
      elevation: 2,
      icon: Icons.line_style,
      borderRadius: 5,
      titleSpacing: 5,
      child: Column(
        children: [
          AlertBlock.warning(child: Text("调整以下参数可能导致检测效果下降，请谨慎修改。")),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AsyncStringInput(
                  label: "置信度",
                  value: "0.6",
                  initialValue: "0.6",
                  prefixIcon: Icon(Icons.fact_check),
                  onSave: (String v) async {
                    return true;
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: AsyncStringInput(
                  label: "NMS",
                  value: "0.6",
                  initialValue: "0.6",
                  prefixIcon: Icon(Icons.all_out),
                  onSave: (String v) async {
                    return true;
                  },
                ),
              ),
            ],
          ),
          Divider(thickness: 1),
          AsyncSwitch(
            enabled: !_enableSYCL && !_disableMultiThread,
            title: Text("多线程处理推理结果"),
            selected: _enableMultiThread,
            onSelected: (bool selected) async {
              setState(() {
                _enableSYCL = false;
                _disableSYCL = selected;
              });
              await Future.delayed(const Duration(seconds: 1));
              setState(() {
                _enableMultiThread = selected;
              });
              return true;
            },
            defaultSelected: false,
            subtitle: Text("提升结果处理性能，在核心数较少的CPU上会严重影响游戏帧数。", style: TextStyle(fontSize: 12)),
          ),
          SizedBox(height: 5),
          AlertBlock.tip(child: Text("推荐在 核心数>8 (核心数非线程数) 的设备上启用此选项。")),
          Divider(thickness: 1),
          AsyncSwitch(
            enabled: !_enableMultiThread && !_disableSYCL,
            title: Text("SYCL处理推理结果"),
            selected: _enableSYCL,
            onSelected: (bool selected) async {
              setState(() {
                _enableMultiThread = false;
                _disableMultiThread = selected;
              });
              await Future.delayed(const Duration(seconds: 1));
              setState(() {
                _enableSYCL = selected;
              });
              return true;
            },
            defaultSelected: false,
            subtitle: Text("利用Intel DPC++异构编程将运算迁移至GPU等设备 (需硬件支持)。", style: TextStyle(fontSize: 12)),
          ),
          SizedBox(height: 5),
          AlertBlock.tip(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("需要支持OpenCL 3.0及以上的设备。"),
                Text("Intel: 酷睿11代及以上的非低功耗平台\nNVIDIA: 需要硬件支持CUDA\nAMD: 仅Linux平台", style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          _enableSYCL ? SizedBox(height: 10) : SizedBox.shrink(),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: _enableSYCL
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AsyncDropdown(
                        label: "SYCL设备类型",
                        items: syclDevices.map((e) => e.type).toSet().toList(),
                        value: selectedSYCLDeviceType,
                        defaultValue: syclDevices.first.type,
                        onChanged: (String v) async {
                          setState(() {
                            selectedSYCLDeviceType = v;
                            final filteredDevices = syclDevices.where((d) => d.type == v).toList();
                            if (filteredDevices.isNotEmpty) {
                              selectedSYCLDevice = filteredDevices.first.name;
                            } else {
                              selectedSYCLDevice = "";
                            }
                          });
                          return true;
                        },
                      ),
                      SizedBox(height: 10),
                      AsyncDropdown(
                        key: ValueKey(selectedSYCLDeviceType),
                        label: "SYCL设备",
                        items: syclDevices.where((d) => d.type == selectedSYCLDeviceType).map((e) => e.name).toList(),
                        value: selectedSYCLDevice,
                        defaultValue: syclDevices.where((d) => d.type == selectedSYCLDeviceType).first.name,
                        onChanged: (String v) async {
                          setState(() {
                            selectedSYCLDevice = v;
                          });
                          return true;
                        },
                      ),
                      SizedBox(height: 5),
                      AlertBlock.note(child: Text("如设备列表为空，请确认系统已安装相应的设备驱动。")),
                    ],
                  )
                : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
