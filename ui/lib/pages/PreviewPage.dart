import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:ui/ffi.dart';
import 'package:ui/widget/AlertBlock.dart';
import 'package:ui/widget/AsyncButton.dart';
import 'package:ui/widget/AsyncDropdown.dart';
import 'package:ui/widget/AsyncInputChip.dart';
import 'package:ui/widget/AsyncStringInput.dart';
import 'package:ui/widget/AsyncSwitch.dart';
import 'package:ui/widget/CustomCard.dart';
import 'package:ui/widget/SmoothScrollView.dart';

class PreviewPage extends StatefulWidget {
  const PreviewPage({super.key});

  @override
  _PreviewPageState createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  Rect _point = Rect.fromPoints(Offset(0, 0), Offset(640, 640));
  int _fpsLimit = 30;
  int _desktopIndex = 1;
  String _windowName = '';
  String _windowClass = '';
  String _processName = '';

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textScheme = Theme.of(context).textTheme;

    return SmoothScrollView(
      scrollSpeed: 2,
      damping: 0.25,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const double minCardWidth = 700;
            const double spacing = 10;

            final int crossAxisCount = math.max(
              1,
              (constraints.maxWidth / (minCardWidth + spacing)).ceil(),
            );
            final double cardWidth =
                (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                crossAxisCount;

            return MasonryGridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              itemCount: 5,
              itemBuilder: (context, index) {
                return switch (index) {
                  0 => SizedBox(
                    width: cardWidth,
                    child: _PreviewCard(colorScheme, textScheme),
                  ),
                  1 => SizedBox(
                    width: cardWidth,
                    child: _EditMatSizeCard(colorScheme, textScheme),
                  ),
                  2 => SizedBox(
                    width: cardWidth,
                    child: _EditMatPluginCard(colorScheme, textScheme),
                  ),
                  3 => SizedBox(
                    width: cardWidth,
                    child: _EditPluginParam(colorScheme, textScheme),
                  ),
                  _ => const SizedBox(),
                };
              },
            );
          },
        ),
      ),
    );
  }

  Widget _PreviewCard(ColorScheme colorScheme, TextTheme textTheme) {
    return CustomCard(
      elevation: 2,
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.5,
                color: Colors.black,
                alignment: Alignment.center,
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Image.network(
                    'https://api.elaina.cat/random/pc',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Divider(thickness: 1),
            Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                Wrap(
                  crossAxisAlignment: .start,
                  verticalDirection: .up,
                  runAlignment: .start,
                  alignment: .start,
                  children: [
                    AsyncInputChip(
                      avatar: Icon(Icons.flash_on, size: 18),
                      tooltip: "尽可能的显示更多画面\n最大限值: 60 FPS\n*性能开销: 高",
                      label: Baseline(
                        baseline: 14,
                        baselineType: TextBaseline.alphabetic,
                        child: Text(
                          '实时画面',
                          style: TextStyle(fontSize: 14, height: 1.0),
                        ),
                      ),
                      selected: () async {
                        return await FFI.invoke(
                              "get_previewPage_field",
                              params: {'field': 'realTime'},
                            )
                            as bool;
                      },
                      onSelected: (val) async {
                        await FFI.invoke(
                          "set_previewPage_field",
                          params: {'field': 'realTime', 'value': val},
                        );
                        setState(() {});
                        return true;
                      },
                    ),
                    const SizedBox(width: 8),
                    AsyncInputChip(
                      avatar: Icon(Icons.lightbulb, size: 18),
                      tooltip: "在画面中标注出推理结果\n*性能开销: 中",
                      label: Baseline(
                        baseline: 14,
                        baselineType: TextBaseline.alphabetic,
                        child: Text(
                          '推理结果',
                          style: TextStyle(fontSize: 14, height: 1.0),
                        ),
                      ),
                      selected: () async {
                        return await FFI.invoke(
                              "get_previewPage_field",
                              params: {'field': 'showDetect'},
                            )
                            as bool;
                      },
                      onSelected: (val) async {
                        await FFI.invoke(
                          "set_previewPage_field",
                          params: {'field': 'showDetect', 'value': val},
                        );
                        setState(() {});
                        return true;
                      },
                    ),
                    const SizedBox(width: 8),
                    AsyncInputChip(
                      avatar: Icon(Icons.speed, size: 18),
                      tooltip: "在画面左上角显示推理FPS与耗时\n*性能开销: 低",
                      label: Baseline(
                        baseline: 14,
                        baselineType: TextBaseline.alphabetic,
                        child: Text(
                          'FPS',
                          style: TextStyle(fontSize: 14, height: 1.0),
                        ),
                      ),
                      selected: () async {
                        return await FFI.invoke(
                              "get_previewPage_field",
                              params: {'field': 'showFPS'},
                            )
                            as bool;
                      },
                      onSelected: (val) async {
                        await FFI.invoke(
                          "set_previewPage_field",
                          params: {'field': 'showFPS', 'value': val},
                        );
                        setState(() {});
                        return true;
                      },
                    ),
                  ],
                ),
                PlayPauseButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _EditMatSizeCard(ColorScheme colorScheme, TextTheme textTheme) {
    final wCtrl = TextEditingController(text: _point.width.toInt().toString());
    final hCtrl = TextEditingController(text: _point.height.toInt().toString());
    final xCtrl = TextEditingController(text: _point.left.toInt().toString());
    final yCtrl = TextEditingController(text: _point.top.toInt().toString());

    Future<bool> syncRect() async {
      final xStr = xCtrl.text.trim();
      final yStr = yCtrl.text.trim();
      final wStr = wCtrl.text.trim();
      final hStr = hCtrl.text.trim();

      final x = int.tryParse(xStr);
      final y = int.tryParse(yStr);
      final w = int.tryParse(wStr);
      final h = int.tryParse(hStr);

      if (x == null || y == null || w == null || h == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            showCloseIcon: true,
            duration: Duration(seconds: 2),
            content: Text('请输入合法的整数坐标/尺寸'),
          ),
        );
        return true;
      }

      setState(() {
        _point = Rect.fromLTWH(
          x.toDouble(),
          y.toDouble(),
          w.toDouble(),
          h.toDouble(),
        );
      });

      await FFI.invoke(
        "set_previewPage_field",
        params: {'field': 'x_offset', 'value': x},
      );
      await FFI.invoke(
        "set_previewPage_field",
        params: {'field': 'y_offset', 'value': y},
      );
      await FFI.invoke(
        "set_previewPage_field",
        params: {'field': 'width', 'value': w},
      );
      await FFI.invoke(
        "set_previewPage_field",
        params: {'field': 'height', 'value': h},
      );
      return true;
    }

    return CustomCard(
      elevation: 2,
      borderRadius: 5,
      title: Baseline(
        baseline: 14,
        baselineType: TextBaseline.alphabetic,
        child: Text('画面大小', style: TextStyle(fontSize: 14, height: 1.0)),
      ),
      icon: Icons.photo_size_select_large,
      titleSpacing: 5,
      color: colorScheme.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AlertBlock.note(child: Text("图像越大推理所需的算力越高, 过高的值可能会导致识别精度下降")),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: AsyncStringInput(
                  controller: wCtrl,
                  label: '宽 (px)',
                  initialValue: '640',
                  value: FFI.invoke(
                    "get_previewPage_field",
                    params: {'field': 'width'},
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AsyncStringInput(
                  controller: hCtrl,
                  label: '高 (px)',
                  initialValue: '640',
                  value: FFI.invoke(
                    "get_previewPage_field",
                    params: {'field': 'height'},
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              verticalDirection: .down,
              mainAxisSize: .min,
              crossAxisAlignment: .end,
              children: [
                AsyncButton(
                  onPressed: () async {
                    xCtrl.text = yCtrl.text = '0';
                    wCtrl.text = hCtrl.text = "640";
                    return await syncRect();
                  },
                  type: .text,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 18),
                      SizedBox(width: 4),
                      Text('重置'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AsyncButton(
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.save, size: 18),
                      SizedBox(width: 4),
                      Text('保存'),
                    ],
                  ),
                  onPressed: () async => await syncRect(),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: (_point.width == 0 || _point.height == 0) ? 1 : 0,
              child: (_point.width == 0 || _point.height == 0)
                  ? Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: AlertBlock.warning(child: Text("捕获图像宽高大小不能为0")),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  List<String> plugins = ['桌面截图', '窗口截图', '交换链截图'];
  String selectedPlugin = '桌面截图';

  Widget _EditMatPluginCard(ColorScheme colorScheme, TextTheme textTheme) {
    return CustomCard(
      elevation: 2,
      borderRadius: 5,
      title: Baseline(
        baseline: 14,
        baselineType: TextBaseline.alphabetic,
        child: Text('捕获模式', style: TextStyle(fontSize: 14, height: 1.0)),
      ),
      titleSpacing: 5,
      icon: Icons.screenshot_monitor,
      color: colorScheme.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 5),
          AsyncDropdown(
            label: '模式',
            value: '桌面截图',
            items: plugins,
            onChanged: (v) async {
              setState(() {
                selectedPlugin = v;
              });
              return true;
            },
          ),
          Divider(thickness: 1),
          const SizedBox(height: 5),
          if (selectedPlugin == '桌面截图')
            _DesktopScreenshot()
          else if (selectedPlugin == '窗口截图')
            _WindowScreenshot()
          else
            _SwapchainScreenshot(),
        ],
      ),
    );
  }

  Widget _EditPluginParam(ColorScheme colorScheme, TextTheme textTheme) {
    return CustomCard(
      elevation: 2,
      borderRadius: 5,
      title: Baseline(
        baseline: 14,
        baselineType: TextBaseline.alphabetic,
        child: Text('捕获参数', style: TextStyle(fontSize: 14, height: 1.0)),
      ),
      icon: Icons.data_thresholding,
      child: Column(
        children: [
          SizedBox(height: 5),
          AsyncStringInput(
            label: "最大捕获帧率",
            initialValue: "30",
            prefixIcon: Icon(Icons.shutter_speed),
            keyboardType: TextInputType.number,
            value: () async => await FFI.invoke(
              "get_previewPage_field",
              params: {'field': 'fps_limit'},
            ),
            onSave: (v) async {
              final fps = int.tryParse(v);
              if (fps != null) {
                await FFI.invoke(
                  "set_previewPage_field",
                  params: {'field': 'fps_limit', 'value': fps},
                );
                _fpsLimit = fps;
                return true;
              }
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('请输入合法的整数值')));
              return false;
            },
          ),
          Divider(thickness: 1),
          AsyncSwitch(
            title: Text("异步捕获"),
            subtitle: Text(
              "使用独立线程进行屏幕捕获，但会增加一帧延迟和资源占用",
              style: TextStyle(fontSize: 13),
            ),
            borderRadius: BorderRadius.circular(5),
            onSelected: (v) async {
              await FFI.invoke(
                "set_previewPage_field",
                params: {'field': 'async_capture', 'value': v},
              );
              return true;
            },
            selected: () async {
              return await FFI.invoke(
                    "get_previewPage_field",
                    params: {'field': 'async_capture'},
                  )
                  as bool;
            },
          ),
          const SizedBox(height: 5),
          AlertBlock.tip(child: Text("推荐开启，仅当CPU资源紧张时关闭")),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _fpsLimit == 0 ? 1 : 0,
              child: _fpsLimit == 0
                  ? Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: AlertBlock.warning(child: Text("捕获帧数上限不能为0")),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _DesktopScreenshot() {
    return AsyncStringInput(
      label: "显示器标识",
      initialValue: "1",
      prefixIcon: Icon(Icons.shutter_speed),
      keyboardType: TextInputType.number,
      value: () async {
        int v = await FFI.invoke(
          "set_previewPage_field",
          params: {'field': 'desktop_index'},
        );
        _desktopIndex = v;
        return v;
      },
      onSave: (v) async {
        final index = int.tryParse(v);
        if (index != null) {
          await FFI.invoke(
            "set_previewPage_field",
            params: {'field': 'desktop_index', 'value': index},
          );
          _desktopIndex = index;
          return true;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请输入合法的整数值')));
        return false;
      },
    );
  }

  Widget _WindowScreenshot() {
    return Column(
      children: [
        AsyncStringInput(
          label: "窗口名称",
          prefixIcon: Icon(Icons.title),
          keyboardType: TextInputType.text,
          value: () async {
            String v = await FFI.invoke(
              "get_previewPage_field",
              params: {'field': 'windows_name'},
            );
            _windowName = v;
            return v;
          },
          onSave: (v) async {
            await FFI.invoke(
              "set_previewPage_field",
              params: {'field': 'windows_name', 'value': v},
            );
            _windowName = v;
            return true;
          },
        ),
        SizedBox(height: 8),
        AsyncStringInput(
          label: "窗口类名",
          prefixIcon: Icon(Icons.tag),
          keyboardType: TextInputType.text,
          value: () async {
            String v = await FFI.invoke(
              "get_previewPage_field",
              params: {'field': 'class_name'},
            );
            _windowName = v;
            return v;
          },
          onSave: (v) async {
            await FFI.invoke(
              "set_previewPage_field",
              params: {'field': 'class_name', 'value': v},
            );
            _windowClass = v;
            return true;
          },
        ),
      ],
    );
  }

  Widget _SwapchainScreenshot() {
    return Column(
      children: [
        AsyncStringInput(
          label: "进程名称",
          prefixIcon: Icon(Icons.vaccines),
          keyboardType: TextInputType.text,
          value: () async {
            String v = await FFI.invoke(
              "get_previewPage_field",
              params: {'field': 'process_name'},
            );
            _processName = v;
            return v;
          },
          onSave: (v) async {
            await FFI.invoke(
              "set_previewPage_field",
              params: {'field': 'process_name', 'value': v},
            );
            _processName = v;
            return true;
          },
        ),
      ],
    );
  }
}

final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);

class PlayPauseButton extends StatelessWidget {
  const PlayPauseButton({super.key});

  @override
  Widget build(BuildContext context) {
    var scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<bool>(
      valueListenable: isPlaying,
      builder: (_, playing, __) {
        return Material(
          type: MaterialType.button,
          color: scheme.primary,
          borderRadius: BorderRadius.circular(5),
          child: InkWell(
            borderRadius: BorderRadius.circular(5),
            hoverColor: scheme.primaryContainer.withAlpha(100),
            focusColor: scheme.primaryContainer.withAlpha(100),
            highlightColor: scheme.primaryContainer.withAlpha(200),
            onTap: () => isPlaying.value = !playing,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                key: ValueKey<bool>(playing),
                mainAxisSize: .min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: playing
                        ? Icon(
                            key: ValueKey("pause"),
                            Icons.pause,
                            color: scheme.onPrimary,
                          )
                        : Icon(
                            key: ValueKey("play_arrow"),
                            Icons.play_arrow,
                            color: scheme.onPrimary,
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
