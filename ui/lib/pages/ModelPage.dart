import 'dart:math' as math;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:ui/widget/AlertBlock.dart';
import 'package:ui/widget/AsyncCheckbox.dart';
import 'package:ui/widget/AsyncDropdown.dart';
import 'package:ui/widget/AsyncStringInput.dart';
import 'package:ui/widget/CustomCard.dart';
import 'package:ui/widget/SmoothScrollView.dart';

class ModelPage extends StatefulWidget {
  const ModelPage({super.key});

  @override
  State<StatefulWidget> createState() => _ModelPageState();
}

class ClassItem {
  String name;
  int id;
  bool isSelected;

  ClassItem(this.name, this.id, this.isSelected);
}

class ModelTypeTag extends StatelessWidget {
  final ModelType type;
  final String? label;

  const ModelTypeTag({Key? key, required this.type, this.label}) : super(key: key);

  Color _colorForType(ModelType t) {
    switch (t) {
      case .onnx:
        return Colors.purple;
      case .tensorrt:
        return Colors.green;
      case .openvino:
        return Colors.blue;
      case .ncnn:
        return Colors.orange;
      case .tflite:
        return Colors.teal;
      case .coreml:
        return Colors.pink;
      case .torchscript:
        return Colors.red;
      case .others:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _colorForType(type);
    final text = (label ?? type.name).toUpperCase();

    return Container(
      height: 25,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11, height: 1, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class ModelElementTag extends StatelessWidget {
  final String element;

  const ModelElementTag({Key? key, required this.element}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 25,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(5)),
      alignment: Alignment.center,
      child: Text(
        element.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 11, height: 1, fontWeight: FontWeight.w500),
      ),
    );
  }
}

enum ModelType { onnx, tensorrt, openvino, ncnn, tflite, coreml, torchscript, others }

class ModelItem {
  String name;
  ModelType type;
  final String element;

  ModelItem(this.name, this.type, this.element);

  String formatDisplayName() {
    return "[${type.name.toUpperCase()}](${element.toUpperCase()}) $name";
  }

  static ModelItem string2ModelItem(String str) {
    final regex = RegExp(r'\[(.+?)\]\((.+?)\)\s+(.+)');
    final match = regex.firstMatch(str);
    if (match != null) {
      final typeStr = match.group(1)!.toLowerCase();
      final elementStr = match.group(2)!;
      final nameStr = match.group(3)!;
      ModelType type;
      switch (typeStr) {
        case 'onnx':
          type = ModelType.onnx;
          break;
        case 'tensorrt':
          type = ModelType.tensorrt;
          break;
        case 'openvino':
          type = ModelType.openvino;
          break;
        case 'ncnn':
          type = ModelType.ncnn;
          break;
        case 'tflite':
          type = ModelType.tflite;
          break;
        case 'coreml':
          type = ModelType.coreml;
          break;
        case 'torchscript':
          type = ModelType.torchscript;
          break;
        default:
          type = ModelType.others;
      }
      return ModelItem(nameStr, type, elementStr);
    } else {
      return ModelItem(str, ModelType.others, "unknown");
    }
  }
}

class _ModelPageState extends State<ModelPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _readNote = false;
  List<ModelItem> models = [ModelItem("yolo11m", .openvino, "fp32"), ModelItem("yolo12m", .openvino, "fp16"), ModelItem("yolo26m", .openvino, "fp32")];
  int selectedModelIndex = 0;
  late String model = models.first.formatDisplayName();
  List<ClassItem> class_ids = [ClassItem("玩家", 0, false), ClassItem("头部", 1, true), ClassItem("躯体", 2, true)];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SmoothScrollView(
      scrollSpeed: 2,
      damping: 0.25,
      child: Column(
        children: [
          AnimatedContainer(
            width: double.infinity,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Listener(child: Container(color: Colors.transparent)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(width: 11),
                        TextButton.icon(
                          onPressed: () => {},
                          label: Baseline(
                            baseline: 17,
                            baselineType: .alphabetic,
                            child: Text('导入模型', style: TextStyle(fontSize: 14)),
                          ),
                          icon: Icon(Icons.folder_zip),
                          style: TextButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer.withAlpha(100),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(onPressed: () => {}, icon: Icon(Icons.refresh)),
                        SizedBox(width: 11),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(thickness: 1, height: 1),
          Padding(
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
                      0 => SizedBox(width: cardWidth, child: _ModuleSelectCard()),
                      1 => SizedBox(width: cardWidth, child: _SelectTag()),
                      _ => const SizedBox(),
                    };
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _ModuleSelectCard() {
    return CustomCard(
      elevation: 2,
      title: Baseline(
        baseline: 14,
        baselineType: TextBaseline.alphabetic,
        child: Text('视觉模型', style: TextStyle(fontSize: 14, height: 1.0)),
      ),
      icon: Icons.batch_prediction,
      borderRadius: 5,
      titleSpacing: 5,
      child: Padding(
        padding: EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: !_readNote ? 1 : 0,
                child: !_readNote
                    ? AlertBlock.caution(
                        icon: Icon(Icons.shield_outlined, size: 20).icon,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('第三方模型', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  const Text(
                                    '使用后，屏幕图像等数据可能被发送至第三方服务器；'
                                    '开发者无法截留、审查或承担任何责任。',
                                  ),
                                  TextButton(
                                    onPressed: () => setState(() => _readNote = true),
                                    style: TextButton.styleFrom(padding: const EdgeInsets.all(0)),
                                    child: Text("我已悉知上述内容"),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            _readNote ? const SizedBox.shrink() : SizedBox(height: 10),
            AsyncDropdown(
              label: "模型",
              items: models.map((e) => e.formatDisplayName()).toList(),
              value: model,
              defaultValue: "",
              onChanged: (String v) async {
                final idx = models.indexWhere((m) => m.formatDisplayName() == v);
                if (idx >= 0) {
                  setState(() {
                    selectedModelIndex = idx;
                    model = models[idx].formatDisplayName();
                  });
                }
                return true;
              },
              itemBuilder: (String item) {
                final modelItem = ModelItem.string2ModelItem(item);
                return Row(
                  children: [
                    Expanded(
                      child: Baseline(baseline: 16, baselineType: TextBaseline.alphabetic, child: Text(modelItem.name)),
                    ),
                    ModelTypeTag(type: modelItem.type),
                    VerticalDivider(thickness: 1),
                    ModelElementTag(element: modelItem.element),
                    VerticalDivider(thickness: 1),
                  ],
                );
              },
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AsyncStringInput(
                    readOnly: true,
                    label: "输入宽度",
                    value: "640",
                    initialValue: "640",
                    prefixIcon: Transform.rotate(angle: pi / 2, child: Icon(Icons.height)),
                    onSave: (String v) async {
                      return true;
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: AsyncStringInput(
                    readOnly: true,
                    label: "输入高度",
                    value: "640",
                    initialValue: "640",
                    prefixIcon: Icon(Icons.height),
                    onSave: (String v) async {
                      return true;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            AlertBlock.note(child: Text("仅支持导出格式为动态调整输入尺寸的模型可以修改以上参数。")),
          ],
        ),
      ),
    );
  }

  Widget _SelectTag() {
    return CustomCard(
      title: Baseline(
        baseline: 14,
        baselineType: TextBaseline.alphabetic,
        child: Text('对象标签', style: TextStyle(fontSize: 14, height: 1.0)),
      ),
      elevation: 2,
      icon: Icons.new_label,
      borderRadius: 5,
      titleSpacing: 5,
      child: Padding(
        padding: EdgeInsets.all(5),
        child: Column(
          children: [
            AlertBlock.note(child: Text("选择需要检测的对象类别，未选择的类别将被忽略。")),
            SizedBox(height: 5),
            for (var i = 0; i < class_ids.length; i++)
              AsyncCheckbox(
                title: Text(class_ids[i].name),
                selected: class_ids[i].isSelected,
                onSelected: (bool selected) async {
                  await Future.delayed(const Duration(seconds: 1));
                  setState(() {
                    class_ids[i].isSelected = selected;
                  });
                  return true;
                },
              ),
          ],
        ),
      ),
    );
  }
}
