import 'dart:async';
import 'dart:math' as math;
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:ui/ffi.dart';
import 'package:ui/widget/AlertBlock.dart';
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

class _PreviewPageState extends State<PreviewPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late final _fpsLimit = FloatField("fps_limit", 120.0);
  late final _windowHeight = IntField("window_height", 640);
  late final _windowWidth = IntField("window_width", 640);
  late final _asyncCapture = BoolField("async_capture", true);
  late final _realTime = BoolField("real_time", false);
  late final _showDetect = BoolField("show_detect", false);
  late final _showFPS = BoolField("show_fps", false);
  late final _desktopName = StringField("desktop_name", '');
  late final _windowName = StringField("window_name", '');
  late final _windowClass = StringField("window_class", '');

  bool _isMonitoring = false;
  bool _isImageHandlerRegistered = false;

  @override
  void initState() {
    super.initState();
    _registerImageHandler();
  }

  void _registerImageHandler() {
    if (_isImageHandlerRegistered) return;

    'push_mat'.cpp.method((args) async {
      if (!_isMonitoring || args == null || !args.containsKey('mat')) return null;

      final matInfo = args['mat'] as Map<dynamic, dynamic>;
      final width = matInfo['width'] as int;
      final height = matInfo['height'] as int;
      final format = matInfo['format'] as String;
      final data = matInfo['data'] as List<int>;

      try {
        if (format == 'jpeg') {
          final codec = await ui.instantiateImageCodec(Uint8List.fromList(data), targetWidth: width, targetHeight: height);
          final frameInfo = await codec.getNextFrame();

          if (mounted) {
            _imageViewKey.currentState?.updateImage(frameInfo.image);
          }
        } else if (format == 'bgra') {
          final image = await createImageFromBgra(Uint8List.fromList(data), width, height);

          if (mounted) {
            _imageViewKey.currentState?.updateImage(image);
          }
        }
      } catch (e) {
        debugPrint('图像解码失败: $e');
      }

      return null;
    });

    _isImageHandlerRegistered = true;
  }

  Future<ui.Image> createImageFromBgra(Uint8List data, int width, int height) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(data, width, height, ui.PixelFormat.bgra8888, (image) => completer.complete(image));
    return completer.future;
  }

  final GlobalKey<_ImageViewState> _imageViewKey = GlobalKey();

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
                  0 => SizedBox(
                    width: cardWidth,
                    child: _PreviewCard(colorScheme, textScheme, _imageViewKey, _isMonitoring, (value) {
                      setState(() {
                        _isMonitoring = value;
                        if (!value) {
                          _imageViewKey.currentState?.clearImage();
                        }
                      });
                    }),
                  ),
                  1 => SizedBox(width: cardWidth, child: _EditMatSizeCard(colorScheme, textScheme)),
                  2 => SizedBox(width: cardWidth, child: _EditMatPluginCard(colorScheme, textScheme)),
                  3 => SizedBox(width: cardWidth, child: _EditPluginParam(colorScheme, textScheme)),
                  _ => const SizedBox(),
                };
              },
            );
          },
        ),
      ),
    );
  }

  Widget _PreviewCard(ColorScheme colorScheme, TextTheme textTheme, GlobalKey<_ImageViewState> imageViewKey, bool isMonitoring, ValueChanged<bool> onMonitoringChanged) {
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
                child: ImageView(key: imageViewKey, isMonitoring: isMonitoring),
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
                      tooltip: "尽可能的显示更多画面\n最大限值: 60 FPS\n*性能开销: 极高",
                      label: Baseline(
                        baseline: 14,
                        baselineType: TextBaseline.alphabetic,
                        child: Text('实时画面', style: TextStyle(fontSize: 14, height: 1.0)),
                      ),
                      selected: () async {
                        return await _realTime.get();
                      },
                      onSelected: (val) async {
                        await _realTime.set(val);
                        setState(() {});
                        return true;
                      },
                    ),
                    const SizedBox(width: 8),
                    AsyncInputChip(
                      avatar: Icon(Icons.lightbulb, size: 18),
                      tooltip: "在画面中标注出推理结果\n*性能开销: 高",
                      label: Baseline(
                        baseline: 14,
                        baselineType: TextBaseline.alphabetic,
                        child: Text('推理结果', style: TextStyle(fontSize: 14, height: 1.0)),
                      ),
                      selected: () async {
                        return await _showDetect.get();
                      },
                      onSelected: (val) async {
                        await _showDetect.set(val);
                        setState(() {});
                        return true;
                      },
                    ),
                    const SizedBox(width: 8),
                    AsyncInputChip(
                      avatar: Icon(Icons.speed, size: 18),
                      tooltip: "在画面左上角显示推理FPS与耗时\n*性能开销: 高",
                      label: Baseline(
                        baseline: 14,
                        baselineType: TextBaseline.alphabetic,
                        child: Text('FPS', style: TextStyle(fontSize: 14, height: 1.0)),
                      ),
                      selected: () async {
                        return await _showFPS.get();
                      },
                      onSelected: (val) async {
                        await _showFPS.set(val);
                        setState(() {});
                        return true;
                      },
                    ),
                  ],
                ),
                PlayPauseButton(
                  onStateChanged: (isPlaying) {
                    setState(() {
                      _isMonitoring = isPlaying;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _EditMatSizeCard(ColorScheme colorScheme, TextTheme textTheme) {
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
                  prefixIcon: Transform.rotate(angle: pi / 2, child: Icon(Icons.height)),
                  label: '宽 (px)',
                  initialValue: '640',
                  value: () async => await _windowWidth.get(),
                  keyboardType: .number,
                  onSave: (String v) async {
                    await _windowWidth.set(int.parse(v));
                    return true;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AsyncStringInput(
                  prefixIcon: Icon(Icons.height),
                  label: '高 (px)',
                  initialValue: '640',
                  value: () async => await _windowHeight.get(),
                  keyboardType: .number,
                  onSave: (String v) async {
                    await _windowHeight.set(int.parse(v));
                    return true;
                  },
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: (_windowWidth.value < 0 || _windowHeight.value < 0) ? 1 : 0,
              child: (_windowWidth.value < 0 || _windowHeight.value < 0)
                  ? Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: AlertBlock.warning(child: Text("捕获图像宽高大小不小于0")),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_DesktopScreenshot(), SizedBox(height: 8), _WindowScreenshot()]),
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
            value: () async => _fpsLimit.get(),
            onSave: (v) async {
              final fps = float.tryParse(v);
              if (fps != null && fps > 0) {
                _fpsLimit.set(fps);
                return true;
              }
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入合法的整数值')));
              return false;
            },
          ),
          Divider(thickness: 1),
          AsyncSwitch(
            title: Text("异步捕获"),
            subtitle: Text("使用独立线程进行屏幕捕获，但会增加一帧延迟和资源占用", style: TextStyle(fontSize: 13)),
            borderRadius: BorderRadius.circular(5),
            onSelected: (v) async {
              await _asyncCapture.set(v);
              return true;
            },
            selected: () async {
              return await _asyncCapture.get();
            },
          ),
          const SizedBox(height: 5),
          AlertBlock.tip(child: Text("推荐开启，仅当CPU资源紧张时关闭")),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _fpsLimit.value == 0.0 ? 1 : 0,
              child: _fpsLimit.value == 0.0
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
    return AsyncDropdown(
      label: "显示器标识",
      defaultValue: "",
      value: () async {
        return await _desktopName.get();
      },
      items: () async {
        final result = await "get_monitor".cpp.invoke();
        if (result is List) {
          return result.map((e) => e.toString()).toList();
        }
        return <String>[];
      },
      onChanged: (String v) async {
        await _desktopName.set(v);
        return true;
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
            return await _windowName.get();
          },
          onSave: (v) async {
            await _windowName.set(v);
            return true;
          },
        ),
        SizedBox(height: 8),
        AsyncStringInput(
          label: "窗口类名",
          prefixIcon: Icon(Icons.tag),
          keyboardType: TextInputType.text,
          value: () async {
            return await _windowClass.get();
          },
          onSave: (v) async {
            await _windowClass.set(v);
            return true;
          },
        ),
      ],
    );
  }
}

class PlayPauseButton extends StatefulWidget {
  final Function(bool)? onStateChanged;

  const PlayPauseButton({super.key, this.onStateChanged});

  @override
  State<PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<PlayPauseButton> {
  final ValueNotifier<bool> _isPlaying = ValueNotifier<bool>(false);
  bool _isLoading = false;

  Future<void> _togglePlayPause() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      if (_isPlaying.value) {
        await 'stop_monitor'.cpp.invoke();
        widget.onStateChanged?.call(false);
        _isPlaying.value = false;
      } else {
        await 'start_monitor'.cpp.invoke();
        _isPlaying.value = true;
        widget.onStateChanged?.call(true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<bool>(
      valueListenable: _isPlaying,
      builder: (context, playing, child) {
        return Material(
          type: MaterialType.button,
          color: scheme.primary,
          borderRadius: BorderRadius.circular(5),
          child: InkWell(
            borderRadius: BorderRadius.circular(5),
            hoverColor: scheme.primaryContainer.withAlpha(100),
            focusColor: scheme.primaryContainer.withAlpha(100),
            highlightColor: scheme.primaryContainer.withAlpha(200),
            onTap: _isLoading ? null : _togglePlayPause,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _isLoading
                        ? SizedBox(
                            key: const ValueKey('loading'),
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary),
                          )
                        : Icon(key: ValueKey(playing ? 'pause' : 'play_arrow'), playing ? Icons.pause : Icons.play_arrow, color: scheme.onPrimary),
                  ),
                  const SizedBox(width: 8),
                  Text(_isLoading ? '正在处理' : (playing ? '停止推理' : '开始推理'), style: TextStyle(color: scheme.onPrimary)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _isPlaying.dispose();
    super.dispose();
  }
}

class ImageView extends StatefulWidget {
  final bool isMonitoring;

  const ImageView({super.key, required this.isMonitoring});

  @override
  State<ImageView> createState() => _ImageViewState();
}

class _ImageViewState extends State<ImageView> {
  ui.Image? _currentImage;

  void updateImage(ui.Image image) {
    if (mounted) {
      setState(() {
        _currentImage = image;
      });
    }
  }

  void clearImage() {
    if (mounted) {
      setState(() {
        _currentImage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isMonitoring) {
      return _buildPlaceholder();
    }

    if (_currentImage != null) {
      return RawImage(image: _currentImage, fit: BoxFit.contain, width: double.infinity, height: double.infinity);
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 8),
          Text('等待画面...', style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Image.network(
      'https://api.elaina.cat/random/pc',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null),
              const SizedBox(height: 8),
              Text('加载网络图...', style: TextStyle(color: Colors.grey[400])),
            ],
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image, size: 48, color: Colors.grey[600]),
              const SizedBox(height: 8),
              Text('图片加载失败', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        );
      },
    );
  }
}
