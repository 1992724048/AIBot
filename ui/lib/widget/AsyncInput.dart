import 'package:flutter/material.dart';

import 'AsyncWidget.dart';

class AsyncInput extends AsyncWidget<String, AsyncInput> {
  final String label;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final ValueChanged<String>? onChanged;

  const AsyncInput({
    super.key,
    super.defaultValue,
    super.getter,
    super.setter,
    super.errorHandler,
    super.timeoutTime = const Duration(seconds: 10),
    super.showDefaultError = true,
    super.drawer,
    super.itemsGetter,
    super.progressNotifier,
    super.readOnlyNotifier,
    this.label = "",
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.textStyle = const TextStyle(fontSize: 14),
    this.textAlign = TextAlign.left,
    this.onChanged,
  });

  factory AsyncInput.withValue({
    Key? key,
    String label = "",
    dynamic value,
    String? initialValue,
    AsyncValueSetter<String>? onSave,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefixIcon,
    TextStyle? textStyle = const TextStyle(fontSize: 14),
    TextAlign textAlign = TextAlign.left,
    ValueChanged<String>? onChanged,
    ErrorCallback? onError,
    Duration timeout = const Duration(seconds: 10),
    bool showDefaultError = true,
    AsyncDrawer<String>? drawer,
    AsyncItemsGetter<String>? itemsGetter,
    ValueNotifier<double>? progress,
    ValueNotifier<bool>? readOnly,
  }) {
    return AsyncInput(
      key: key,
      label: label,
      defaultValue: value is String ? value : initialValue,
      getter: value is AsyncValueGetter<String> ? value : null,
      setter: onSave,
      errorHandler: onError,
      timeoutTime: timeout,
      showDefaultError: showDefaultError,
      drawer: drawer,
      itemsGetter: itemsGetter,
      keyboardType: keyboardType,
      prefixIcon: prefixIcon,
      textStyle: textStyle,
      textAlign: textAlign,
      onChanged: onChanged,
      progressNotifier: progress,
      readOnlyNotifier: readOnly,
    );
  }

  @override
  AsyncInput copyWith({
    String? defaultValue,
    AsyncValueGetter<String>? getter,
    AsyncValueSetter<String>? setter,
    ErrorCallback? errorHandler,
    Duration? timeout,
    bool? showDefaultError,
    AsyncDrawer<String>? drawer,
    AsyncItemsGetter<String>? itemsGetter,
    ValueNotifier<double>? progressNotifier,
    ValueNotifier<bool>? readOnlyNotifier,
    String? label,
    TextInputType? keyboardType,
    Widget? prefixIcon,
    TextStyle? textStyle,
    TextAlign? textAlign,
    ValueChanged<String>? onChanged,
  }) {
    return AsyncInput(
      key: key,
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
      label: label ?? this.label,
      keyboardType: keyboardType ?? this.keyboardType,
      prefixIcon: prefixIcon ?? this.prefixIcon,
      textStyle: textStyle ?? this.textStyle,
      textAlign: textAlign ?? this.textAlign,
      onChanged: onChanged ?? this.onChanged,
    );
  }

  @override
  State<AsyncInput> createState() => _AsyncInputState();
}

class _AsyncInputState extends AsyncWidgetState<String, AsyncInput> {
  late final TextEditingController _controller;
  String? _lastSyncValue;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.text = widget.defaultValue ?? '';
    _lastSyncValue = widget.defaultValue;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget buildContent(BuildContext context, String? value, bool busy, double? progress, List<String>? items) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final currentValue = value ?? '';
    if (_lastSyncValue != currentValue) {
      _controller.text = currentValue;
      _lastSyncValue = currentValue;
    }
    Widget? suffixIcon;

    final bool hasSetter = widget.setter != null;
    final bool isEditable = !readOnly;

    if (progress != null && progress != -1) {
      suffixIcon = SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(key: Key(progress.toString()), value: progress, strokeWidth: 2),
      );
    } else if (busy) {
      suffixIcon = const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2));
    } else if (!hasSetter) {
      suffixIcon = const SizedBox.shrink();
    } else if (readOnly) {
      suffixIcon = const Icon(Icons.lock, size: 18);
    } else {
      suffixIcon = Padding(
        padding: const EdgeInsets.only(right: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(tooltip: "重置", icon: const Icon(Icons.refresh, size: 18), onPressed: busy ? null : _onResetPressed),
            IconButton(tooltip: "保存", icon: const Icon(Icons.save, size: 18), onPressed: busy ? null : _onSavePressed),
          ],
        ),
      );
    }

    return TextField(
      controller: _controller,
      enabled: !busy && isEditable,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      style: widget.textStyle,
      textAlign: widget.textAlign,
      readOnly: readOnly || busy,
      decoration: InputDecoration(
        prefixIconConstraints: const BoxConstraints(maxWidth: 40, maxHeight: 40, minHeight: 0, minWidth: 0),
        filled: true,
        fillColor: colorScheme.surface,
        labelText: widget.label,
        prefixIcon: widget.prefixIcon != null ? Center(child: widget.prefixIcon) : null,
        suffixIcon: AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: suffixIcon),
      ),
    );
  }

  void _onSavePressed() => _save(_controller.text);

  void _onResetPressed() {
    final target = widget.defaultValue ?? '';
    _controller.text = target;
    _save(target);
  }

  Future<void> _save(String newValue) => changeValue(newValue);
}
