import 'dart:async';

import 'package:flutter/material.dart';

typedef AsyncValueSetter = Future<bool> Function(String value);
typedef AsyncValueGetter = Future<dynamic> Function();
typedef ErrorCallback = void Function(Object error, StackTrace? stack);
typedef OnChanged = void Function(String string);

class AsyncStringInput extends StatefulWidget {
  final String label;
  final String initialValue;
  final AsyncValueSetter? onSave;
  final OnChanged? onChanged;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final dynamic value;
  final Duration timeout;
  final ErrorCallback? onError;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final bool readOnly;
  final TextEditingController? controller;

  const AsyncStringInput({
    super.key,
    this.label = "",
    this.initialValue = "",
    this.onSave,
    this.keyboardType = .text,
    this.prefixIcon,
    this.value,
    this.timeout = const Duration(seconds: 10),
    this.onError,
    this.onChanged,
    this.textStyle = const TextStyle(fontSize: 14),
    this.textAlign = .left,
    this.readOnly = false,
    this.controller,
  });

  @override
  State<AsyncStringInput> createState() => _AsyncStringInputState();
}

class _AsyncStringInputState extends State<AsyncStringInput> {
  late final TextEditingController _controller;
  bool _saving = false;
  bool _loading = false;
  late final bool _internalController;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller = TextEditingController();
      _internalController = true;
    } else {
      _controller = widget.controller!;
      _internalController = false;
    }
    _initValue();
  }

  @override
  void dispose() {
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _initValue() async {
    final val = widget.value;
    if (val == null) {
      _controller.text = widget.initialValue;
    } else if (val is String) {
      _controller.text = val;
    } else if (val is AsyncValueGetter) {
      setState(() => _loading = true);
      try {
        final result = await val().timeout(widget.timeout);
        if (mounted) _controller.text = result.toString();
      } on TimeoutException catch (e, s) {
        _handleError(e, s);
        _controller.text = widget.initialValue;
      } catch (e, s) {
        _handleError(e, s);
        _controller.text = widget.initialValue;
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    } else {
      throw ArgumentError('value 必须是 String 或 AsyncValueGetter 当前是:$val');
    }
  }

  Future<void> _save(String value) async {
    if (_saving) return;

    final oldValue = _controller.text;
    setState(() => _saving = true);

    try {
      if (widget.onSave == null) {
        return;
      }

      final success = await widget.onSave?.call(value).timeout(widget.timeout);
      if (!success!) {
        _handleError(StateError('保存被拒绝'));
        _controller.text = oldValue;
      }
    } on TimeoutException catch (e, s) {
      _handleError(e, s);
      _controller.text = oldValue;
    } catch (e, s) {
      _handleError(e, s);
      _controller.text = oldValue;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _handleError(Object error, [StackTrace? stack]) {
    if (widget.onError != null) {
      widget.onError!(error, stack);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(showCloseIcon: true, duration: Duration(seconds: 2), content: Text('操作失败: $error')));
        }
      });
    }
  }

  void _onSavePressed() => _save(_controller.text);

  void _onResetPressed() {
    _controller.text = widget.initialValue;
    _save(widget.initialValue);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: !_saving && !_loading,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      style: widget.textStyle,
      textAlign: widget.textAlign,
      readOnly: widget.readOnly,
      decoration: InputDecoration(
        enabled: !widget.readOnly,
        labelText: widget.label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        prefixIcon: widget.prefixIcon != null
            ? Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: widget.prefixIcon)
            : null,
        suffixIcon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: widget.onSave == null || widget.readOnly
              ? widget.readOnly
                    ? Icon(Icons.lock, size: 18)
                    : const SizedBox.shrink(key: ValueKey('empty'))
              : Padding(
                  key: ValueKey(_loading || _saving ? 'busy' : 'idle'),
                  padding: const EdgeInsets.only(right: 5),
                  child: _loading
                      ? const Center(
                          child: SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: "重置",
                              icon: const Icon(Icons.refresh, size: 18),
                              onPressed: _onResetPressed,
                            ),
                            IconButton(
                              tooltip: "保存",
                              icon: _saving
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.save, size: 18),
                              onPressed: _onSavePressed,
                            ),
                          ],
                        ),
                ),
        ),
      ),
    );
  }
}
