import 'package:flutter/material.dart';

import 'AsyncWidget.dart';

class AsyncChip extends AsyncWidget<bool, AsyncChip> {
  final Widget label;
  final Widget? avatar;
  final String? tooltip;
  final Color? selectedColor;

  const AsyncChip({
    super.key,
    required this.label,
    this.avatar,
    this.tooltip,
    this.selectedColor,
    super.defaultValue = false,
    super.getter,
    super.setter,
    super.errorHandler,
    super.timeoutTime,
    super.showDefaultError,
    super.drawer,
    super.itemsGetter,
    super.progressNotifier,
    super.readOnlyNotifier,
  });

  @override
  AsyncChip copyWith({
    bool? defaultValue,
    AsyncValueGetter<bool>? getter,
    AsyncValueSetter<bool>? setter,
    ErrorCallback? errorHandler,
    Duration? timeout,
    bool? showDefaultError,
    AsyncDrawer<bool>? drawer,
    AsyncItemsGetter<bool>? itemsGetter,
    ValueNotifier<double>? progressNotifier,
    ValueNotifier<bool>? readOnlyNotifier,
  }) {
    return AsyncChip(
      key: key,
      label: label,
      avatar: avatar,
      tooltip: tooltip,
      selectedColor: selectedColor,
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
    );
  }

  @override
  State<AsyncChip> createState() => _AsyncChipState();
}

class _AsyncChipState extends AsyncWidgetState<bool, AsyncChip> {
  @override
  Widget buildContent(BuildContext context, bool? value, bool busy, double? progress, List<bool>? items) {
    final selected = value ?? false;

    Widget? avatarWidget;

    final hasProgress = progress != null && progress != -1;

    if (hasProgress) {
      avatarWidget = SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(key: ValueKey(progress), value: progress, strokeWidth: 2),
      );
    } else if (busy) {
      avatarWidget = const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2));
    } else if (widget.avatar != null) {
      avatarWidget = SizedBox(width: 18, height: 18, child: Center(child: widget.avatar));
    }

    return InputChip(
      tooltip: widget.tooltip,
      selected: selected,
      selectedColor: widget.selectedColor,
      showCheckmark: widget.avatar == null,
      avatar: AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: avatarWidget ?? const SizedBox.shrink()),
      label: widget.label,
      onSelected: busy || readOnly ? null : changeValue,
    );
  }
}
