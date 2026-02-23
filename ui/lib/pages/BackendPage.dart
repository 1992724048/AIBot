import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:ui/widget/AlertBlock.dart';
import 'package:ui/widget/AsyncDropdown.dart';
import 'package:ui/widget/AsyncStringInput.dart';
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
  static final _backendName = StringField('backend_name', '');
  static final _deviceName = StringField('device_name', '');

  @override
  Future<void> initState() async {
    super.initState();

    final _ = await _backendName.get();
    final _ = await _deviceName.get();
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
              label: '后端框架',
              items: () async {
                final result = await "get_backends".cpp.invoke();
                if (result is List) {
                  return result.cast<String>();
                }
                return <String>[];
              },
              onChanged: (value) async {
                await _backendName.set(value);
                return true;
              },
              value: () async => await _backendName.get(),
            ),
            AnimatedBuilder(
              animation: _backendName,
              builder: (context, child) {
                if (_backendName.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [
                    const Divider(height: 16, thickness: 1),
                    AsyncDropdown(
                      label: '设备名称',
                      items: () async {
                        final result = await "get_devices".cpp.invoke();
                        if (result is List) {
                          return result.cast<String>();
                        }
                        return <String>[];
                      },
                      onChanged: (value) async {
                        await _deviceName.set(value);
                        return true;
                      },
                      value: () async => await _deviceName.get(),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class ResultProcess extends StatefulWidget {
  const ResultProcess({super.key});

  @override
  State<StatefulWidget> createState() => _ResultProcessState();
}

class _ResultProcessState extends State<ResultProcess> {
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
        ],
      ),
    );
  }
}
