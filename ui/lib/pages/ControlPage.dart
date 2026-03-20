import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:ui/ffi.dart';
import 'package:ui/widget/AsyncDropdown.dart';
import 'package:ui/widget/AsyncInput.dart';
import 'package:ui/widget/AsyncSwitch.dart';
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
  final autoFireHotKey = Int32ListField("ControlPage::auto_fire_hot_key", Int32List(0));
  final device = IntField("ControlPage::device", 0);
  final autoFire = BoolField("ControlPage::auto_fire", false);
  final deviceMode = ['Windows API', 'ESP32S3 HID (BLE)'];

  static const icons = {'Windows API': Icon(Icons.desktop_windows), 'ESP32S3 HID (BLE)': Icon(Icons.bluetooth)};

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
                subtitle: Text("用于触发自动瞄准的快捷键", style: TextStyle(fontSize: 13)),
                mode: .GetAsyncKeyState,
              )
              .get(() async {
                List<LogicalKeyboardKey> k = [];
                final ks = await keys.get();
                for (int i = 0; i < ks.length; i++) {
                  final key = ks[i];
                  final mappedKey = vkToLogicalKeyboardKey(key);
                  if (mappedKey != null) {
                    k.add(mappedKey);
                  }
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
          HotkeyRecordWidget(
                title: Text("自动扳机开关热键"),
                subtitle: Text("用于控制自动扳机是否启用", style: TextStyle(fontSize: 13)),
              )
              .get(() async {
                List<LogicalKeyboardKey> k = [];
                final ks = await autoFireHotKey.get();
                for (int i = 0; i < ks.length; i++) {
                  final key = ks[i];
                  final mappedKey = vkToLogicalKeyboardKey(key);
                  if (mappedKey != null) {
                    k.add(mappedKey);
                  }
                }
                return k;
              })
              .set((v) async {
                var k = Int32List(v.length);
                for (int i = 0; i < v.length; i++) {
                  k[i] = logicalKeyboardKeyToVk(v[i])!;
                }
                await autoFireHotKey.set(k);
                return true;
              }),
          Divider(),
          ValueListenableBuilder(
            valueListenable: autoFire,
            builder: (context, value, child) => AsyncSwitch(
              defaultValue: value,
              title: Text('自动扳机'),
              subtitle: Text('准星在检测框内自动开火'),
            ).get(() async => value).set((v) async => await autoFire.set(v)),
          ),
          Divider(),
          AsyncDropdown(
                label: "接口类型",
                itemBeginBuilder: (String item) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      icons[item] ?? const Icon(Icons.question_mark),
                      const SizedBox(width: 3),
                      const VerticalDivider(thickness: 2, indent: 8, endIndent: 8),
                    ],
                  );
                },
              )
              .get(() async => deviceMode[await device.get()])
              .set((v) async {
                await device.set(deviceMode.indexOf(v));
                return true;
              })
              .items(() async => deviceMode),
          ValueListenableBuilder(
            valueListenable: device,
            builder: (context, value, child) {
              switch (device.value) {
                case 1:
                  return Column(children: [Divider(), ESP32S3BLE()]);
                case 0:
                  break;
                default:
              }
              return const SizedBox.shrink();
            },
          ),
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
  final speed = FloatField("ControlPage::speed", 1);
  final x_ = FloatField("ControlPage::x", 50);
  final y_ = FloatField("ControlPage::y", 20);

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
          AsyncInput(
            label: "移动速度",
            keyboardType: .number,
            prefixIcon: Icon(Icons.speed),
          ).get(() async => (await speed.get()).toString()).set((String value) async {
            final v = double.tryParse(value);
            if (v == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入合法整数')));
              return false;
            }
            if (v > 100 || v < 1) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入[1, 100]的数值区间')));
              return false;
            }
            await speed.set(v);
            return true;
          }),
          Divider(),
          AsyncInput(
            label: "X位置百分比",
            keyboardType: .number,
            prefixIcon: Icon(Icons.speed),
          ).get(() async => (await x_.get()).toString()).set((String value) async {
            final v = double.tryParse(value);
            if (v == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入合法整数')));
              return false;
            }
            if (v > 100 || v < 1) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入[1, 100]的数值区间')));
              return false;
            }
            await x_.set(v);
            return true;
          }),
          SizedBox(height: 5),
          AsyncInput(
            label: "Y位置百分比",
            keyboardType: .number,
            prefixIcon: Icon(Icons.speed),
          ).get(() async => (await y_.get()).toString()).set((String value) async {
            final v = double.tryParse(value);
            if (v == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入合法整数')));
              return false;
            }
            if (v > 100 || v < 1) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入[1, 100]的数值区间')));
              return false;
            }
            await y_.set(v);
            return true;
          }),
        ],
      ),
    );
  }
}

class ESP32S3BLE extends StatefulWidget {
  const ESP32S3BLE({super.key});

  @override
  State<StatefulWidget> createState() => _ESP32S3BLEState();
}

class _ESP32S3BLEState extends State<ESP32S3BLE> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: 'get_ble_device'.cpp.invoke(),
      builder: (context, snapshot) {
        Widget leftContent;
        if (snapshot.connectionState == ConnectionState.waiting) {
          leftContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(height: 16, width: 120, color: Colors.grey.shade300),
                  const SizedBox(width: 4),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(height: 12, width: 160, color: Colors.grey.shade300),
            ],
          );
        } else if (!snapshot.hasData) {
          leftContent = const Text("未获取到设备");
        } else {
          final value = snapshot.data as Map;

          if (value.isEmpty) {
            leftContent = const Text("无设备");
          } else {
            final status = value['status'] as bool;
            final name = value['name'] as String;
            final addr = value['addr'] as int;

            final data = status ? formatAddr(addr) : '未连接设备';
            final title = status ? name : '无设备';

            leftContent = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(title),
                    const SizedBox(width: 4),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: status ? Colors.green : Colors.red, shape: BoxShape.circle),
                    ),
                  ],
                ),
                Text(data, style: const TextStyle(fontSize: 12)),
              ],
            );
          }
        }

        return Row(
          children: [
            Expanded(child: leftContent),
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() {});
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String formatAddr(int addr) {
    final hex = addr.toRadixString(16).padLeft(12, '0').toUpperCase();
    return hex.replaceAllMapped(RegExp(r'.{2}'), (m) => '${m.group(0)}:').substring(0, 17);
  }
}
