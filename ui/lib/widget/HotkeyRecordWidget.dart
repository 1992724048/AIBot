import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'AsyncWidget.dart';

enum HotKeyMode { RegisterHotKey, GetAsyncKeyState }

class HotkeyRecordWidget extends AsyncWidget<List<LogicalKeyboardKey>, HotkeyRecordWidget> {
  final Widget title;
  final Widget? subtitle;
  final HotKeyMode mode;

  const HotkeyRecordWidget({
    super.key,
    super.defaultValue,
    super.getter,
    super.setter,
    super.errorHandler,
    super.timeoutTime,
    super.showDefaultError,
    super.drawer,
    super.itemsGetter,
    super.progressNotifier,
    super.readOnlyNotifier,
    required this.title,
    this.subtitle,
    this.mode = HotKeyMode.RegisterHotKey,
  });

  @override
  HotkeyRecordWidget copyWith({
    List<LogicalKeyboardKey>? defaultValue,
    AsyncValueGetter<List<LogicalKeyboardKey>>? getter,
    AsyncValueSetter<List<LogicalKeyboardKey>>? setter,
    ErrorCallback? errorHandler,
    Duration? timeout,
    bool? showDefaultError,
    AsyncDrawer<List<LogicalKeyboardKey>>? drawer,
    AsyncItemsGetter<List<LogicalKeyboardKey>>? itemsGetter,
    ValueNotifier<double>? progressNotifier,
    ValueNotifier<bool>? readOnlyNotifier,
  }) {
    return HotkeyRecordWidget(
      defaultValue: defaultValue ?? this.defaultValue,
      getter: getter ?? this.getter,
      setter: setter ?? this.setter,
      errorHandler: errorHandler ?? this.errorHandler,
      timeoutTime: timeout ?? this.timeoutTime,
      showDefaultError: showDefaultError ?? this.showDefaultError,
      drawer: drawer ?? this.drawer,
      itemsGetter: itemsGetter ?? this.itemsGetter,
      progressNotifier: progressNotifier ?? this.progressNotifier,
      readOnlyNotifier: readOnlyNotifier ?? this.readOnlyNotifier,
      title: this.title,
      subtitle: this.subtitle,
    );
  }

  @override
  State<HotkeyRecordWidget> createState() => _HotkeyRecordWidgetState();
}

class _HotkeyRecordWidgetState extends AsyncWidgetState<List<LogicalKeyboardKey>, HotkeyRecordWidget> {
  @override
  Widget buildContent(
    BuildContext context,
    List<LogicalKeyboardKey>? value,
    bool busy,
    double? progress,
    List<List<LogicalKeyboardKey>>? items,
  ) {
    final isEmpty = value == null || value.isEmpty;
    final canInteract = !busy && !readOnly;
    final hasProgress = progress != null && progress != -1;

    return Material(
      color: Colors.transparent,
      borderRadius: const BorderRadius.all(Radius.circular(5)),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        onTap: canInteract ? _openRecorder : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedOpacity(
              opacity: canInteract ? 1.0 : 0.5,
              duration: const Duration(milliseconds: 150),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [widget.title, if (widget.subtitle != null) widget.subtitle!],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isEmpty)
                        Text(
                          "未设置",
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        )
                      else
                        Wrap(children: value.map((k) => _buildKeyBlock(_keyToString(k))).toList()),
                      const SizedBox(width: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                        child: (busy || hasProgress)
                            ? SizedBox(
                                key: const ValueKey("progress"),
                                width: 40,
                                child: LinearProgressIndicator(value: hasProgress ? progress : null, minHeight: 2),
                              )
                            : IconButton(
                                key: const ValueKey("edit"),
                                icon: const Icon(Icons.edit),
                                onPressed: canInteract ? _openRecorder : null,
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openRecorder() async {
    final result = await showDialog<List<LogicalKeyboardKey>>(
      context: context,
      builder: (_) => _HotkeyRecordDialog(mode: widget.mode),
    );
    if (result != null) {
      await changeValue(result);
    }
  }

  Widget _buildKeyBlock(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.surface),
      ),
    );
  }

  String _keyToString(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.control) return "Ctrl";
    if (key == LogicalKeyboardKey.controlLeft) return "LCtrl";
    if (key == LogicalKeyboardKey.controlRight) return "RCtrl";
    if (key == LogicalKeyboardKey.shift) return "Shift";
    if (key == LogicalKeyboardKey.shiftLeft) return "LShift";
    if (key == LogicalKeyboardKey.shiftRight) return "RShift";
    if (key == LogicalKeyboardKey.alt) return "Alt";
    if (key == LogicalKeyboardKey.altLeft) return "RAlt";
    if (key == LogicalKeyboardKey.altRight) return "LAlt";
    if (key == LogicalKeyboardKey.meta) return "Meta";
    if (key == LogicalKeyboardKey.metaLeft) return "LMeta";
    if (key == LogicalKeyboardKey.metaRight) return "RMeta";
    if (key == MouseLogicalKeyboardKey.mouseLeft) return "Mouse Left";
    if (key == MouseLogicalKeyboardKey.mouseRight) return "Mouse Right";
    if (key == MouseLogicalKeyboardKey.mouseMiddle) return "Mouse Middle";
    if (key == MouseLogicalKeyboardKey.mouseBack) return "Mouse Back";
    if (key == MouseLogicalKeyboardKey.mouseForward) return "Mouse Forward";

    return key.keyLabel.isNotEmpty ? key.keyLabel.toUpperCase() : key.debugName ?? "";
  }
}

class _HotkeyRecordDialog extends StatefulWidget {
  final HotKeyMode mode;

  const _HotkeyRecordDialog({required this.mode});

  @override
  State<_HotkeyRecordDialog> createState() => _HotkeyRecordDialogState();
}

class _HotkeyRecordDialogState extends State<_HotkeyRecordDialog> {
  final Set<LogicalKeyboardKey> _modifiers = {};
  LogicalKeyboardKey? _mainKey;

  bool _isModifier(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight ||
        key == LogicalKeyboardKey.shift ||
        key == LogicalKeyboardKey.alt ||
        key == LogicalKeyboardKey.meta ||
        key == LogicalKeyboardKey.control;
  }

  String _keyToString(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.space) return "Space";
    if (key == LogicalKeyboardKey.control) return "Ctrl";
    if (key == LogicalKeyboardKey.controlLeft) return "LCtrl";
    if (key == LogicalKeyboardKey.controlRight) return "RCtrl";
    if (key == LogicalKeyboardKey.shift) return "Shift";
    if (key == LogicalKeyboardKey.shiftLeft) return "LShift";
    if (key == LogicalKeyboardKey.shiftRight) return "RShift";
    if (key == LogicalKeyboardKey.alt) return "Alt";
    if (key == LogicalKeyboardKey.altLeft) return "RAlt";
    if (key == LogicalKeyboardKey.altRight) return "LAlt";
    if (key == LogicalKeyboardKey.meta) return "Meta";
    if (key == LogicalKeyboardKey.metaLeft) return "LMeta";
    if (key == LogicalKeyboardKey.metaRight) return "RMeta";
    if (key == MouseLogicalKeyboardKey.mouseLeft) return "Mouse Left";
    if (key == MouseLogicalKeyboardKey.mouseRight) return "Mouse Right";
    if (key == MouseLogicalKeyboardKey.mouseMiddle) return "Mouse Middle";
    if (key == MouseLogicalKeyboardKey.mouseBack) return "Mouse Back";
    if (key == MouseLogicalKeyboardKey.mouseForward) return "Mouse Forward";

    return key.keyLabel.isNotEmpty ? key.keyLabel.toUpperCase() : key.debugName ?? "";
  }

  List<LogicalKeyboardKey> _orderedKeys() {
    final ordered = <LogicalKeyboardKey>[];

    if (_modifiers.contains(LogicalKeyboardKey.control)) {
      ordered.add(LogicalKeyboardKey.control);
    }
    if (_modifiers.contains(LogicalKeyboardKey.controlLeft)) {
      ordered.add(LogicalKeyboardKey.controlLeft);
    }
    if (_modifiers.contains(LogicalKeyboardKey.controlRight)) {
      ordered.add(LogicalKeyboardKey.controlRight);
    }
    if (_modifiers.contains(LogicalKeyboardKey.shift)) {
      ordered.add(LogicalKeyboardKey.shift);
    }
    if (_modifiers.contains(LogicalKeyboardKey.shiftLeft)) {
      ordered.add(LogicalKeyboardKey.shiftLeft);
    }
    if (_modifiers.contains(LogicalKeyboardKey.shiftRight)) {
      ordered.add(LogicalKeyboardKey.shiftRight);
    }
    if (_modifiers.contains(LogicalKeyboardKey.alt)) {
      ordered.add(LogicalKeyboardKey.alt);
    }
    if (_modifiers.contains(LogicalKeyboardKey.altRight)) {
      ordered.add(LogicalKeyboardKey.altRight);
    }
    if (_modifiers.contains(LogicalKeyboardKey.altLeft)) {
      ordered.add(LogicalKeyboardKey.altLeft);
    }
    if (_modifiers.contains(LogicalKeyboardKey.meta)) {
      ordered.add(LogicalKeyboardKey.meta);
    }
    if (_modifiers.contains(LogicalKeyboardKey.metaLeft)) {
      ordered.add(LogicalKeyboardKey.metaLeft);
    }
    if (_modifiers.contains(LogicalKeyboardKey.metaRight)) {
      ordered.add(LogicalKeyboardKey.metaRight);
    }

    if (_mainKey != null) {
      ordered.add(_mainKey!);
    }

    return ordered;
  }

  List<LogicalKeyboardKey> _format() {
    final keys = _orderedKeys();
    if (keys.isEmpty) return [];
    return keys.toList();
  }

  Widget _buildKeyBlock(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.surface),
      ),
    );
  }

  Widget _buildDisplay() {
    final keys = _orderedKeys();

    if (keys.isEmpty) {
      return Text("按下组合键${ widget.mode == .RegisterHotKey ? '' : ' (支持鼠标)' }", style: TextStyle(color: Colors.grey));
    }

    return Wrap(alignment: WrapAlignment.center, children: keys.map((k) => _buildKeyBlock(_keyToString(k))).toList());
  }

  void _clear() {
    setState(() {
      _modifiers.clear();
      _mainKey = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    void onPointerDown(PointerDownEvent event) {
      LogicalKeyboardKey? key;
      switch (event.buttons) {
        case kPrimaryMouseButton:
          key = MouseLogicalKeyboardKey.mouseLeft;
          break;
        case kSecondaryMouseButton:
          key = MouseLogicalKeyboardKey.mouseRight;
          break;
        case kMiddleMouseButton:
          key = MouseLogicalKeyboardKey.mouseMiddle;
          break;
        case kBackMouseButton:
          key = MouseLogicalKeyboardKey.mouseBack;
          break;
        case kForwardMouseButton:
          key = MouseLogicalKeyboardKey.mouseForward;
          break;
      }
      if (key != null) {
        setState(() {
          _mainKey = key;
        });
      }
    }

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 200),
      contentPadding: const EdgeInsets.all(20),
      content: SizedBox(
        width: 320,
        height: 140,
        child: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              final key = event.logicalKey;
              if (key == LogicalKeyboardKey.escape) {
                Navigator.of(context).pop(null);
                return KeyEventResult.handled;
              }
              if (_isModifier(key)) {
                _modifiers.add(key);
              } else {
                _mainKey = key;
              }
              setState(() {});
              return KeyEventResult.handled;
            }
            return KeyEventResult.handled;
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: widget.mode == HotKeyMode.GetAsyncKeyState
                      ? Listener(onPointerDown: onPointerDown, child: _buildDisplay())
                      : _buildDisplay(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: _clear, child: const Text("清除")),
                  Row(
                    children: [
                      TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text("取消")),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: () => Navigator.of(context).pop(_format()), child: const Text("保存")),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MouseLogicalKeyboardKey {
  static const LogicalKeyboardKey mouseLeft = LogicalKeyboardKey(0x200000001);
  static const LogicalKeyboardKey mouseRight = LogicalKeyboardKey(0x200000002);
  static const LogicalKeyboardKey mouseMiddle = LogicalKeyboardKey(0x200000003);
  static const LogicalKeyboardKey mouseBack = LogicalKeyboardKey(0x200000004);
  static const LogicalKeyboardKey mouseForward = LogicalKeyboardKey(0x200000005);
}

int? logicalKeyboardKeyToVk(LogicalKeyboardKey key) {
  final Map<LogicalKeyboardKey, int> specialKeyMap = {
    LogicalKeyboardKey.control: 0x11, // Ctrl
    LogicalKeyboardKey.shift: 0x10, // Shift
    LogicalKeyboardKey.alt: 0x12, // ALT
    // 功能键
    LogicalKeyboardKey.f1: 0x70, // VK_F1
    LogicalKeyboardKey.f2: 0x71, // VK_F2
    LogicalKeyboardKey.f3: 0x72, // VK_F3
    LogicalKeyboardKey.f4: 0x73, // VK_F4
    LogicalKeyboardKey.f5: 0x74, // VK_F5
    LogicalKeyboardKey.f6: 0x75, // VK_F6
    LogicalKeyboardKey.f7: 0x76, // VK_F7
    LogicalKeyboardKey.f8: 0x77, // VK_F8
    LogicalKeyboardKey.f9: 0x78, // VK_F9
    LogicalKeyboardKey.f10: 0x79, // VK_F10
    LogicalKeyboardKey.f11: 0x7A, // VK_F11
    LogicalKeyboardKey.f12: 0x7B, // VK_F12
    // 控制键
    LogicalKeyboardKey.enter: 0x0D, // VK_RETURN
    LogicalKeyboardKey.tab: 0x09, // VK_TAB
    LogicalKeyboardKey.space: 0x20, // VK_SPACE
    LogicalKeyboardKey.backspace: 0x08, // VK_BACK
    LogicalKeyboardKey.escape: 0x1B, // VK_ESCAPE
    LogicalKeyboardKey.delete: 0x2E, // VK_DELETE
    LogicalKeyboardKey.insert: 0x2D, // VK_INSERT
    LogicalKeyboardKey.home: 0x24, // VK_HOME
    LogicalKeyboardKey.end: 0x23, // VK_END
    LogicalKeyboardKey.pageUp: 0x21, // VK_PRIOR
    LogicalKeyboardKey.pageDown: 0x22, // VK_NEXT
    // 方向键
    LogicalKeyboardKey.arrowUp: 0x26, // VK_UP
    LogicalKeyboardKey.arrowDown: 0x28, // VK_DOWN
    LogicalKeyboardKey.arrowLeft: 0x25, // VK_LEFT
    LogicalKeyboardKey.arrowRight: 0x27, // VK_RIGHT
    // 修饰键
    LogicalKeyboardKey.shiftLeft: 0xA0, // VK_LSHIFT
    LogicalKeyboardKey.shiftRight: 0xA1, // VK_RSHIFT
    LogicalKeyboardKey.controlLeft: 0xA2, // VK_LCONTROL
    LogicalKeyboardKey.controlRight: 0xA3, // VK_RCONTROL
    LogicalKeyboardKey.altLeft: 0xA4, // VK_LMENU
    LogicalKeyboardKey.altRight: 0xA5, // VK_RMENU
    LogicalKeyboardKey.metaLeft: 0x5B, // VK_LWIN
    LogicalKeyboardKey.metaRight: 0x5C, // VK_RWIN
    // 数字键盘
    LogicalKeyboardKey.numpad0: 0x60, // VK_NUMPAD0
    LogicalKeyboardKey.numpad1: 0x61, // VK_NUMPAD1
    LogicalKeyboardKey.numpad2: 0x62, // VK_NUMPAD2
    LogicalKeyboardKey.numpad3: 0x63, // VK_NUMPAD3
    LogicalKeyboardKey.numpad4: 0x64, // VK_NUMPAD4
    LogicalKeyboardKey.numpad5: 0x65, // VK_NUMPAD5
    LogicalKeyboardKey.numpad6: 0x66, // VK_NUMPAD6
    LogicalKeyboardKey.numpad7: 0x67, // VK_NUMPAD7
    LogicalKeyboardKey.numpad8: 0x68, // VK_NUMPAD8
    LogicalKeyboardKey.numpad9: 0x69, // VK_NUMPAD9
    LogicalKeyboardKey.numpadMultiply: 0x6A, // VK_MULTIPLY
    LogicalKeyboardKey.numpadAdd: 0x6B, // VK_ADD
    LogicalKeyboardKey.numpadSubtract: 0x6D, // VK_SUBTRACT
    LogicalKeyboardKey.numpadDecimal: 0x6E, // VK_DECIMAL
    LogicalKeyboardKey.numpadDivide: 0x6F, // VK_DIVIDE
    // 其他
    LogicalKeyboardKey.pause: 0x13, // VK_PAUSE
    LogicalKeyboardKey.capsLock: 0x14, // VK_CAPITAL
    LogicalKeyboardKey.scrollLock: 0x91, // VK_SCROLL
    LogicalKeyboardKey.printScreen: 0x2C, // VK_SNAPSHOT
    // 标点符号
    LogicalKeyboardKey.comma: 0xBC, // VK_OEM_COMMA
    LogicalKeyboardKey.period: 0xBE, // VK_OEM_PERIOD
    LogicalKeyboardKey.semicolon: 0xBA, // VK_OEM_1
    LogicalKeyboardKey.quote: 0xDE, // VK_OEM_7
    LogicalKeyboardKey.bracketLeft: 0xDB, // VK_OEM_4
    LogicalKeyboardKey.bracketRight: 0xDD, // VK_OEM_6
    LogicalKeyboardKey.backslash: 0xDC, // VK_OEM_5
    LogicalKeyboardKey.minus: 0xBD, // VK_OEM_MINUS
    LogicalKeyboardKey.equal: 0xBB, // VK_OEM_PLUS
    LogicalKeyboardKey.slash: 0xBF, // VK_OEM_2
    LogicalKeyboardKey.backquote: 0xC0, // VK_OEM_3
    // 鼠标
    MouseLogicalKeyboardKey.mouseLeft: 0x01, // VK_LBUTTON
    MouseLogicalKeyboardKey.mouseRight: 0x02, // VK_RBUTTON
    MouseLogicalKeyboardKey.mouseMiddle: 0x04, // VK_MBUTTON
    MouseLogicalKeyboardKey.mouseBack: 0x05, // VK_XBUTTON1
    MouseLogicalKeyboardKey.mouseForward: 0x06, // VK_XBUTTON2
  };

  if (specialKeyMap.containsKey(key)) {
    return specialKeyMap[key];
  }

  if (key.keyId >= 0x61 && key.keyId <= 0x7A) {
    return key.keyId - 0x20;
  }

  if (key.keyId >= 0x30 && key.keyId <= 0x39) {
    return key.keyId;
  }

  return null;
}

LogicalKeyboardKey? vkToLogicalKeyboardKey(int vkCode) {
  final Map<int, LogicalKeyboardKey> vkToKeyMap = {
    0x11: LogicalKeyboardKey.control, // Ctrl
    0x10: LogicalKeyboardKey.shift, // Shift
    0x12: LogicalKeyboardKey.alt, // Shift
    // 功能键
    0x70: LogicalKeyboardKey.f1, // VK_F1
    0x71: LogicalKeyboardKey.f2, // VK_F2
    0x72: LogicalKeyboardKey.f3, // VK_F3
    0x73: LogicalKeyboardKey.f4, // VK_F4
    0x74: LogicalKeyboardKey.f5, // VK_F5
    0x75: LogicalKeyboardKey.f6, // VK_F6
    0x76: LogicalKeyboardKey.f7, // VK_F7
    0x77: LogicalKeyboardKey.f8, // VK_F8
    0x78: LogicalKeyboardKey.f9, // VK_F9
    0x79: LogicalKeyboardKey.f10, // VK_F10
    0x7A: LogicalKeyboardKey.f11, // VK_F11
    0x7B: LogicalKeyboardKey.f12, // VK_F12
    // 控制键
    0x0D: LogicalKeyboardKey.enter, // VK_RETURN
    0x09: LogicalKeyboardKey.tab, // VK_TAB
    0x20: LogicalKeyboardKey.space, // VK_SPACE
    0x08: LogicalKeyboardKey.backspace, // VK_BACK
    0x1B: LogicalKeyboardKey.escape, // VK_ESCAPE
    0x2E: LogicalKeyboardKey.delete, // VK_DELETE
    0x2D: LogicalKeyboardKey.insert, // VK_INSERT
    0x24: LogicalKeyboardKey.home, // VK_HOME
    0x23: LogicalKeyboardKey.end, // VK_END
    0x21: LogicalKeyboardKey.pageUp, // VK_PRIOR
    0x22: LogicalKeyboardKey.pageDown, // VK_NEXT
    // 方向键
    0x26: LogicalKeyboardKey.arrowUp, // VK_UP
    0x28: LogicalKeyboardKey.arrowDown, // VK_DOWN
    0x25: LogicalKeyboardKey.arrowLeft, // VK_LEFT
    0x27: LogicalKeyboardKey.arrowRight, // VK_RIGHT
    // 修饰键
    0xA0: LogicalKeyboardKey.shiftLeft, // VK_LSHIFT
    0xA1: LogicalKeyboardKey.shiftRight, // VK_RSHIFT
    0xA2: LogicalKeyboardKey.controlLeft, // VK_LCONTROL
    0xA3: LogicalKeyboardKey.controlRight, // VK_RCONTROL
    0xA4: LogicalKeyboardKey.altLeft, // VK_LMENU
    0xA5: LogicalKeyboardKey.altRight, // VK_RMENU
    0x5B: LogicalKeyboardKey.metaLeft, // VK_LWIN
    0x5C: LogicalKeyboardKey.metaRight, // VK_RWIN
    // 数字键盘
    0x60: LogicalKeyboardKey.numpad0, // VK_NUMPAD0
    0x61: LogicalKeyboardKey.numpad1, // VK_NUMPAD1
    0x62: LogicalKeyboardKey.numpad2, // VK_NUMPAD2
    0x63: LogicalKeyboardKey.numpad3, // VK_NUMPAD3
    0x64: LogicalKeyboardKey.numpad4, // VK_NUMPAD4
    0x65: LogicalKeyboardKey.numpad5, // VK_NUMPAD5
    0x66: LogicalKeyboardKey.numpad6, // VK_NUMPAD6
    0x67: LogicalKeyboardKey.numpad7, // VK_NUMPAD7
    0x68: LogicalKeyboardKey.numpad8, // VK_NUMPAD8
    0x69: LogicalKeyboardKey.numpad9, // VK_NUMPAD9
    0x6A: LogicalKeyboardKey.numpadMultiply, // VK_MULTIPLY
    0x6B: LogicalKeyboardKey.numpadAdd, // VK_ADD
    0x6D: LogicalKeyboardKey.numpadSubtract, // VK_SUBTRACT
    0x6E: LogicalKeyboardKey.numpadDecimal, // VK_DECIMAL
    0x6F: LogicalKeyboardKey.numpadDivide, // VK_DIVIDE
    // 其他
    0x13: LogicalKeyboardKey.pause, // VK_PAUSE
    0x14: LogicalKeyboardKey.capsLock, // VK_CAPITAL
    0x91: LogicalKeyboardKey.scrollLock, // VK_SCROLL
    0x2C: LogicalKeyboardKey.printScreen, // VK_SNAPSHOT
    // 标点符号
    0xBC: LogicalKeyboardKey.comma, // VK_OEM_COMMA
    0xBE: LogicalKeyboardKey.period, // VK_OEM_PERIOD
    0xBA: LogicalKeyboardKey.semicolon, // VK_OEM_1
    0xDE: LogicalKeyboardKey.quote, // VK_OEM_7
    0xDB: LogicalKeyboardKey.bracketLeft, // VK_OEM_4
    0xDD: LogicalKeyboardKey.bracketRight, // VK_OEM_6
    0xDC: LogicalKeyboardKey.backslash, // VK_OEM_5
    0xBD: LogicalKeyboardKey.minus, // VK_OEM_MINUS
    0xBB: LogicalKeyboardKey.equal, // VK_OEM_PLUS
    0xBF: LogicalKeyboardKey.slash, // VK_OEM_2
    0xC0: LogicalKeyboardKey.backquote, // VK_OEM_3
    // 鼠标
    0x01: MouseLogicalKeyboardKey.mouseLeft, // VK_LBUTTON
    0x02: MouseLogicalKeyboardKey.mouseRight, // VK_RBUTTON
    0x04: MouseLogicalKeyboardKey.mouseMiddle, // VK_MBUTTON
    0x05: MouseLogicalKeyboardKey.mouseBack, // VK_XBUTTON1
    0x06: MouseLogicalKeyboardKey.mouseForward, // VK_XBUTTON2
  };

  if (vkToKeyMap.containsKey(vkCode)) {
    return vkToKeyMap[vkCode];
  }

  if (vkCode >= 0x41 && vkCode <= 0x5A) {
    return LogicalKeyboardKey(vkCode + 0x20);
  }

  if (vkCode >= 0x30 && vkCode <= 0x39) {
    return LogicalKeyboardKey(vkCode);
  }

  return null;
}
