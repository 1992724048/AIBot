import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:ui/widget/AlertBlock.dart';
import 'package:ui/widget/AsyncDropdown.dart';
import 'package:ui/widget/AsyncInput.dart';
import 'package:ui/widget/CustomCard.dart';
import 'package:ui/widget/SmoothScrollView.dart';

import '../ffi.dart';

class BackendPage extends StatefulWidget {
  const BackendPage({super.key});

  @override
  State<BackendPage> createState() => _BackendPageState();
}

class _BackendPageState extends State<BackendPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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
                  0 => SizedBox(width: cardWidth, child: SelectBackend()),
                  1 => SizedBox(width: cardWidth, child: ResultProcess()),
                  _ => const SizedBox(),
                };
              },
            );
          },
        ),
      ),
    );
  }
}

class SelectBackend extends StatefulWidget {
  const SelectBackend({super.key});

  @override
  State<StatefulWidget> createState() => _SelectBackendState();
}

class _SelectBackendState extends State<SelectBackend> {
  static final _backendName = StringField('BackendPage::backend_name', '');
  static final _deviceName = StringField('BackendPage::device_name', '');

  static final icons = {
    'OpenVINO': ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Image.asset("images/intel.png", width: 28, height: 28, fit: BoxFit.cover),
    ),
  };
  static final iconsDevice = {
    'IntelCoreUltra': ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Image.asset("images/core_ultra.webp", width: 28, height: 28, fit: BoxFit.cover),
    ),
    'IntelCore': ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Image.asset("images/intel_core.webp", width: 28, height: 28, fit: BoxFit.cover),
    ),
    'IntelGraphics': ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Image.asset("images/iris_xe.png", width: 28, height: 28, fit: BoxFit.cover),
    ),
    'IntelArc': ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Image.asset("images/intel_arc.png", width: 28, height: 28, fit: BoxFit.cover),
    ),
    'IntelXeon': ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Image.asset("images/xeon.webp", width: 28, height: 28, fit: BoxFit.cover),
    ),
    'IntelNPU': ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Image.asset("images/npu.png", width: 28, height: 28, fit: BoxFit.cover),
    ),
    'NVIDIA': ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Image.asset("images/nvidia.png", width: 28, height: 28, fit: BoxFit.cover),
    ),
    'AMD': ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Image.asset("images/amd.png", width: 28, height: 28, fit: BoxFit.cover),
    ),
  };

  static Map<RegExp, String> get _regexMatchers => {
    RegExp(r'core.*ultra|ultra\s*\d+|core\s*ultra', caseSensitive: false): 'IntelCoreUltra',
    RegExp(r'core(?![^u]*ultra)|core\s*i[3579]|intel.*core(?!.*ultra)', caseSensitive: false): 'IntelCore',
    RegExp(r'iris|uhd|graphics|xe\s*graphics', caseSensitive: false): 'IntelGraphics',
    RegExp(r'arc\s*a?\d+|intel.*arc', caseSensitive: false): 'IntelArc',
    RegExp(r'xeon', caseSensitive: false): 'IntelXeon',
    RegExp(r'npu|neural.*processing', caseSensitive: false): 'IntelNPU',
    RegExp(r'nvidia|geforce|rtx|gtx|titan|quadro', caseSensitive: false): 'NVIDIA',
    RegExp(r'amd|ryzen|radeon|threadripper|epyc', caseSensitive: false): 'AMD',
  };

  static Widget getDeviceIcon(String item) {
    for (var entry in _regexMatchers.entries) {
      if (entry.key.hasMatch(item)) {
        return iconsDevice[entry.value] ?? const Icon(Icons.question_mark);
      }
    }
    return const Icon(Icons.question_mark);
  }

  @override
  void initState() {
    super.initState();
    _backendName.addListener(_onBackendChanged);
  }

  @override
  void dispose() {
    _backendName.removeListener(_onBackendChanged);
    super.dispose();
  }

  void _onBackendChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  timeoutTime: Duration(days: 1),
                  label: '后端框架',
                  itemBeginBuilder: (String item) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [icons[item] ?? const Icon(Icons.question_mark), const SizedBox(width: 3), const VerticalDivider(thickness: 2, indent: 8, endIndent: 8)],
                    );
                  },
                )
                .items(() async {
                  final result = await "get_backends".cpp.invoke();
                  if (result is List) {
                    return result.cast<String>();
                  }
                  return <String>[];
                })
                .get(() async => await _backendName.get())
                .set((value) async {
                  await _backendName.set(value);
                  await _deviceName.set('');
                  return true;
                }),
            ValueListenableBuilder<String>(
              valueListenable: _backendName,
              builder: (context, backendValue, child) {
                if (backendValue.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [
                    const Divider(height: 16, thickness: 1),
                    AsyncDropdown(
                          label: '设备名称',
                          key: ValueKey(backendValue),
                          itemBeginBuilder: (String item) {
                            return Row(mainAxisSize: MainAxisSize.min, children: [getDeviceIcon(item), const SizedBox(width: 3), const VerticalDivider(thickness: 2, indent: 8, endIndent: 8)]);
                          },
                        )
                        .items(() async {
                          final result = await "get_devices".cpp.invoke();
                          if (result is List) {
                            return result.cast<String>();
                          }
                          return <String>[];
                        })
                        .get(() async => await _deviceName.get())
                        .set((value) async {
                          await _deviceName.set(value);
                          return true;
                        })
                        .timeout(Duration(minutes: 1)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ResultProcess extends StatefulWidget {
  const ResultProcess({super.key});

  @override
  State<StatefulWidget> createState() => _ResultProcessState();
}

class _ResultProcessState extends State<ResultProcess> {
  static final _nms = FloatField('BackendPage::nms', 0.5);
  static final _confidence = FloatField('BackendPage::confidence', 0.5);

  @override
  Widget build(BuildContext context) {
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
          SizedBox(height: 8),
          AlertBlock.note(child: Text("是否需要 NMS 由模型决定，部分模型不需要 NMS (如yolo26)")),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AsyncInput(label: "置信度", defaultValue: "0.6", prefixIcon: Icon(Icons.fact_check), keyboardType: .number).get(() async => (await _confidence.get()).toString()).set((
                  String v,
                ) async {
                  await _confidence.set(double.parse(v));
                  return true;
                }),
              ),
              SizedBox(width: 12),
              Expanded(
                child: AsyncInput(label: "NMS", defaultValue: "0.6", prefixIcon: Icon(Icons.all_out), keyboardType: .number).get(() async => (await _nms.get()).toString()).set((String v) async {
                  await _nms.set(double.parse(v));
                  return true;
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
