import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:ui/ffi.dart';
import 'package:ui/widget/AlertBlock.dart';
import 'package:ui/widget/AsyncCheckbox.dart';
import 'package:ui/widget/AsyncDropdown.dart';
import 'package:ui/widget/CustomCard.dart';
import 'package:ui/widget/SmoothScrollView.dart';

final _modelName = StringField("ModelPage::model_name", '');
Map<String, Map<int, String>> currentTagMap = {};
Map<String, Map<int, bool>> currentSelect = {};

class ModelPage extends StatefulWidget {
  const ModelPage({super.key});

  @override
  State<StatefulWidget> createState() => _ModelPageState();
}

class _ModelPageState extends State<ModelPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SmoothScrollView(
      scrollSpeed: 2,
      damping: 0.25,
      child: Column(
        children: [
          ImportModel(),
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
                      0 => SizedBox(width: cardWidth, child: ModelCard()),
                      1 => SizedBox(width: cardWidth, child: ModelTag()),
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
}

class ModelCard extends StatefulWidget {
  const ModelCard({super.key});

  @override
  State<StatefulWidget> createState() => _ModelCardState();
}

class _ModelCardState extends State<ModelCard> {
  List<ModelItem> items = [];

  static final icons = {
    'yolo': ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Image.asset("images/yolo.png", width: 28, height: 28, fit: BoxFit.cover),
    ),
  };

  static Map<RegExp, String> get _regexMatchers => {RegExp(r'yolo.*', caseSensitive: false): 'yolo'};

  static Widget getIcon(String item) {
    for (var entry in _regexMatchers.entries) {
      if (entry.key.hasMatch(item)) {
        return icons[entry.value] ?? const Icon(Icons.question_mark);
      }
    }
    return const Icon(Icons.question_mark);
  }

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: .start,
        children: [
          NoteCard(),
          AsyncDropdown(
                timeoutTime: Duration(days: 1),
                label: "模型",
                itemBeginBuilder: (String item) {
                  return Row(mainAxisSize: MainAxisSize.min, children: [getIcon(item), const SizedBox(width: 3), const VerticalDivider(thickness: 2, indent: 8, endIndent: 8)]);
                },
                itemEndBuilder: (String item) {
                  final v = items.where((m) => m.name == item).toList();
                  final modelItem = v[0];
                  return Row(
                    children: [
                      ModelTypeTag(type: modelItem.type),
                      VerticalDivider(thickness: 2, indent: 8, endIndent: 8),
                      ModelElementTag(element: modelItem.element),
                      VerticalDivider(thickness: 2, indent: 8, endIndent: 8),
                    ],
                  );
                },
              )
              .items(() async {
                items.clear();
                final listMap = await "get_models".cpp.invoke() as List;
                for (Map item in listMap) {
                  final name = item['name']?.toString() ?? '';
                  final backend = item['backend']?.toString() ?? '';
                  final tagMap = item['tag_map'] as Map;
                  final strArr = backend.split(':');
                  if (strArr.length == 2) {
                    items.add(ModelItem(name, ModelType.fromString(strArr[0]), strArr[1], tagMap.cast<int, String>()));
                  }
                }
                final v = await _modelName.get();
                if (v.isEmpty) {
                  await _modelName.set(listMap[0]['name']);
                }
                return items.map((e) => e.name).toList();
              })
              .get(() async {
                final v = await _modelName.get();
                final item = items.where((e) => v == e.name);
                currentTagMap[v] = item.first.tagMap;
                currentSelect[v] = (await "get_tag".cpp.invoke({"name": v}) as Map).cast<int, bool>();
                return v;
              })
              .set((String v) async {
                final item = items.where((m) => m.name == v);
                if (item.isEmpty) {
                  return false;
                }
                await _modelName.set(v);
                currentTagMap[v] = item.first.tagMap;
                currentSelect[v] = (await "get_tag".cpp.invoke({"name": v}) as Map).cast<int, bool>();
                return true;
              })
              .timeout(Duration(minutes: 1)),
        ],
      ),
    );
  }
}

class ModelTag extends StatefulWidget {
  const ModelTag({super.key});

  @override
  State<StatefulWidget> createState() => _ModelTagState();
}

class _ModelTagState extends State<ModelTag> {
  static final _modelName = StringField("ModelPage::model_name", '');

  @override
  Widget build(BuildContext context) {
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
      child: ValueListenableBuilder(
        valueListenable: _modelName,
        builder: (context, value, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AlertBlock.note(child: Text("选择需要检测的对象类别，未选择的类别将被忽略。")),
              SizedBox(height: 5),
              if (value.isNotEmpty && currentTagMap[value]!.isNotEmpty)
                Column(
                  children: [
                    for (var i = 0; i < currentTagMap[value]!.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: AsyncCheckbox(key: Key('${value}_$i'), title: Text(currentTagMap[value]![i]!)).get(() async => currentSelect[value]?[i] ?? false).set((bool selected) async {
                          final name = value;
                          await "set_tag".cpp.invoke({"name": name, "tag": i, "select": selected});
                          currentSelect[value]?[i] = selected;
                          return true;
                        }),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class ImportModel extends StatefulWidget {
  const ImportModel({super.key});

  @override
  State<StatefulWidget> createState() => _ImportModelState();
}

class _ImportModelState extends State<ImportModel> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
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
    );
  }
}

class ClassItem {
  String name;
  int id;
  bool isSelected;

  ClassItem(this.name, this.id, this.isSelected);
}

enum ModelType {
  onnx,
  tensorrt,
  openvino,
  ncnn,
  tflite,
  coreml,
  torchscript,
  others;

  static ModelType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'onnx':
        return ModelType.onnx;
      case 'tensorrt':
      case 'tensor_rt':
      case 'trt':
        return ModelType.tensorrt;
      case 'openvino':
      case 'open_vino':
        return ModelType.openvino;
      case 'ncnn':
        return ModelType.ncnn;
      case 'tflite':
      case 'tensorflow_lite':
        return ModelType.tflite;
      case 'coreml':
      case 'core_ml':
        return ModelType.coreml;
      case 'torchscript':
      case 'torch_script':
        return ModelType.torchscript;
      default:
        return ModelType.others;
    }
  }

  String toShortString() {
    return toString().split('.').last;
  }

  String get displayName {
    switch (this) {
      case ModelType.onnx:
        return 'ONNX';
      case ModelType.tensorrt:
        return 'TensorRT';
      case ModelType.openvino:
        return 'OpenVINO';
      case ModelType.ncnn:
        return 'NCNN';
      case ModelType.tflite:
        return 'TFLite';
      case ModelType.coreml:
        return 'CoreML';
      case ModelType.torchscript:
        return 'TorchScript';
      case ModelType.others:
        return 'Other';
    }
  }
}

class ModelTypeTag extends StatelessWidget {
  final ModelType type;
  final String? label;

  const ModelTypeTag({super.key, required this.type, this.label});

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

  const ModelElementTag({super.key, required this.element});

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

class ModelItem {
  String name;
  ModelType type;
  String element;
  Map<int, String> tagMap;

  ModelItem(this.name, this.type, this.element, this.tagMap);
}

class NoteCard extends StatefulWidget {
  const NoteCard({super.key});

  @override
  State<StatefulWidget> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  bool _readNote = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: !_readNote ? 1 : 0,
        child: !_readNote
            ? Column(
                children: [
                  AlertBlock.caution(
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
                  ),
                  const SizedBox(height: 5),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
