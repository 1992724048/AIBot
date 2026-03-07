import 'package:flutter/material.dart';

import 'AsyncWidget.dart';

class AsyncRadio<T> extends AsyncWidget<T, AsyncRadio<T>> {
  final T value;

  const AsyncRadio({
    super.key,
    required this.value,
    required T defaultValue,
    super.getter,
    super.setter,
    super.errorHandler,
    super.timeoutTime,
    super.showDefaultError,
    super.progressNotifier,
    super.readOnlyNotifier,
  }) : super(defaultValue: defaultValue);

  @override
  AsyncRadio<T> copyWith({
    T? defaultValue,
    AsyncValueGetter<T>? getter,
    AsyncValueSetter<T>? setter,
    ErrorCallback? errorHandler,
    Duration? timeout,
    bool? showDefaultError,
    AsyncDrawer<T>? drawer,
    AsyncItemsGetter<T>? itemsGetter,
    ValueNotifier<double>? progressNotifier,
    ValueNotifier<bool>? readOnlyNotifier,
  }) {
    return AsyncRadio<T>(
      key: key,
      value: value,
      defaultValue: defaultValue ?? this.defaultValue!,
      getter: getter ?? this.getter,
      setter: setter ?? this.setter,
      errorHandler: errorHandler ?? this.errorHandler,
      timeoutTime: timeout ?? this.timeoutTime,
      showDefaultError: showDefaultError ?? this.showDefaultError,
      progressNotifier: progressNotifier ?? this.progressNotifier,
      readOnlyNotifier: readOnlyNotifier ?? this.readOnlyNotifier,
    );
  }

  @override
  State<AsyncRadio<T>> createState() => _AsyncRadioState<T>();
}

class _AsyncRadioState<T> extends AsyncWidgetState<T, AsyncRadio<T>> {
  @override
  Widget buildContent(BuildContext context, T? groupValue, bool busy, double? progress, List<T>? items) {
    final canInteract = !busy && !readOnly && widget.setter != null;
    final hasProgress = progress != null && progress != -1;
    Widget? overlay;

    if (hasProgress) {
      overlay = CircularProgressIndicator(value: progress, strokeWidth: 2);
    } else if (busy) {
      overlay = const CircularProgressIndicator(strokeWidth: 2);
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Radio<T>(value: widget.value, groupValue: groupValue, onChanged: canInteract ? (_) => changeValue(widget.value) : null),
        if (overlay != null) IgnorePointer(child: SizedBox.square(dimension: 24, child: overlay)),
      ],
    );
  }
}
