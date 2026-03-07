import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:ui/ffi.dart';
import 'package:ui/widget/AsyncDropdown.dart';
import 'package:ui/widget/AsyncInput.dart';
import 'package:ui/widget/CustomCard.dart';

import '../widget/HotkeyRecordWidget.dart';
import '../widget/SmoothScrollView.dart';

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<StatefulWidget> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> with AutomaticKeepAliveClientMixin {
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
                  0 => SizedBox(width: cardWidth, child: MouseControl()),
                  1 => SizedBox(width: cardWidth, child: MoveAlgorithm()),
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

class MouseControl extends StatefulWidget {
  const MouseControl({super.key});

  @override
  State<StatefulWidget> createState() => _MouseControl();
}

class _MouseControl extends State<MouseControl> {
  final keys = Int32ListField("ControlPage::keys", Int32List(0));

  static const icons = {'Windows API': Icon(Icons.desktop_windows), 'ESP32S3 HID (蓝牙)': Icon(Icons.bluetooth), 'ESP32S3 HID (USB)': Icon(Icons.usb)};

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      elevation: 2,
      title: Baseline(
        baseline: 14,
        baselineType: TextBaseline.alphabetic,
        child: Text('鼠标接口', style: TextStyle(fontSize: 14, height: 1.0)),
      ),
      icon: Icons.mouse,
      borderRadius: 5,
      titleSpacing: 5,
      child: Column(
        children: [
          HotkeyRecordWidget(
                title: Text("瞄准快捷键"),
                subtitle: Text("用于启用自动瞄准的快捷键", style: TextStyle(fontSize: 13)),
              )
              .get(() async {
                List<LogicalKeyboardKey> k = [];
                final ks = await keys.get();
                for (final key in ks) {
                  k.add(vkToLogicalKeyboardKey(key)!);
                }
                return k;
              })
              .set((v) async {
                var k = Int32List(v.length);
                for (int i = 0; i < v.length; i++) {
                  k[i] = logicalKeyboardKeyToVk(v[i])!;
                }
                await keys.set(k);
                return true;
              }),
          Divider(),
          AsyncDropdown(
                label: "接口类型",
                itemBeginBuilder: (String item) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [icons[item] ?? const Icon(Icons.question_mark), const SizedBox(width: 3), const VerticalDivider(thickness: 2, indent: 8, endIndent: 8)],
                  );
                },
              )
              .get(() async => '')
              .set((v) async {
                await Future.delayed(Duration(seconds: 2));
                return true;
              })
              .items(() async => ['Windows API', 'ESP32S3 HID (蓝牙)', 'ESP32S3 HID (USB)']),
        ],
      ),
    );
  }
}

class MoveAlgorithm extends StatefulWidget {
  const MoveAlgorithm({super.key});

  @override
  State<StatefulWidget> createState() => _MoveAlgorithmState();
}

class _MoveAlgorithmState extends State<MoveAlgorithm> {
  final speed = FloatField("ControlPage::speed", 0.5);

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      elevation: 2,
      title: Baseline(
        baseline: 14,
        baselineType: TextBaseline.alphabetic,
        child: Text('移动算法', style: TextStyle(fontSize: 14, height: 1.0)),
      ),
      icon: Icons.model_training,
      borderRadius: 5,
      titleSpacing: 5,
      child: Column(
        children: [
          AsyncInput(label: "移动速度", keyboardType: .number, prefixIcon: Icon(Icons.speed)).get(() async => (await speed.get()).toString()).set((String value) async {
            final v = double.tryParse(value);
            if (v == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入合法整数')));
              return false;
            }
            if (v > 100 || v <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入[1, 100]的数值区间')));
              return false;
            }
            await speed.set(v);
            return true;
          }),
        ],
      ),
    );
  }
}
