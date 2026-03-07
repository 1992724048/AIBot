import 'package:flutter/material.dart';

import 'AsyncWidget.dart';

class AsyncSwitchButton extends AsyncWidget<bool, AsyncSwitchButton> {
  final bool enabled;

  const AsyncSwitchButton({
    super.key,
    super.defaultValue = false,
    super.getter,
    super.setter,
    super.errorHandler,
    super.timeoutTime,
    super.showDefaultError,
    super.progressNotifier,
    super.readOnlyNotifier,
    this.enabled = true,
  });

  @override
  AsyncSwitchButton copyWith({
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
    return AsyncSwitchButton(
      key: key,
      defaultValue: defaultValue ?? this.defaultValue,
      getter: getter ?? this.getter,
      setter: setter ?? this.setter,
      errorHandler: errorHandler ?? this.errorHandler,
      timeoutTime: timeout ?? this.timeoutTime,
      showDefaultError: showDefaultError ?? this.showDefaultError,
      progressNotifier: progressNotifier ?? this.progressNotifier,
      readOnlyNotifier: readOnlyNotifier ?? this.readOnlyNotifier,
      enabled: enabled,
    );
  }

  @override
  State<AsyncSwitchButton> createState() => _AsyncSwitchButtonState();
}

class _AsyncSwitchButtonState extends AsyncWidgetState<bool, AsyncSwitchButton> {
  @override
  Widget buildContent(BuildContext context, bool? value, bool busy, double? progress, List<bool>? items) {
    final selected = value ?? false;

    final canInteract = widget.enabled && !busy && !readOnly;

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
        Switch(value: selected, onChanged: canInteract ? changeValue : null),

        if (overlay != null) IgnorePointer(child: SizedBox.square(dimension: 24, child: overlay)),
      ],
    );
  }
}
