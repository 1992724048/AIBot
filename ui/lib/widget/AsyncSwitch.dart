import 'package:flutter/material.dart';

import 'AsyncWidget.dart';

class AsyncSwitch extends AsyncWidget<bool, AsyncSwitch> {
  final Widget? title;
  final Widget? subtitle;
  final BorderRadius borderRadius;
  final bool enabled;

  const AsyncSwitch({
    super.key,
    super.defaultValue = false,
    super.getter,
    super.setter,
    super.errorHandler,
    super.timeoutTime,
    super.showDefaultError,
    super.progressNotifier,
    super.readOnlyNotifier,
    this.title,
    this.subtitle,
    this.borderRadius = const BorderRadius.all(Radius.circular(5)),
    this.enabled = true,
  });

  @override
  AsyncSwitch copyWith({
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
    return AsyncSwitch(
      key: key,
      defaultValue: defaultValue ?? this.defaultValue,
      getter: getter ?? this.getter,
      setter: setter ?? this.setter,
      errorHandler: errorHandler ?? this.errorHandler,
      timeoutTime: timeout ?? this.timeoutTime,
      showDefaultError: showDefaultError ?? this.showDefaultError,
      progressNotifier: progressNotifier ?? this.progressNotifier,
      readOnlyNotifier: readOnlyNotifier ?? this.readOnlyNotifier,
      title: title,
      subtitle: subtitle,
      borderRadius: borderRadius,
      enabled: enabled,
    );
  }

  @override
  State<AsyncSwitch> createState() => _AsyncSwitchState();
}

class _AsyncSwitchState extends AsyncWidgetState<bool, AsyncSwitch> {
  @override
  Widget buildContent(BuildContext context, bool? value, bool busy, double? progress, List<bool>? items) {
    final selected = value ?? false;

    final canInteract = widget.enabled && !busy && !readOnly;

    final hasProgress = progress != null && progress != -1;

    Widget progressBar;

    if (hasProgress) {
      progressBar = LinearProgressIndicator(value: progress, minHeight: 2);
    } else if (busy) {
      progressBar = const LinearProgressIndicator(minHeight: 2);
    } else {
      progressBar = const SizedBox(height: 2);
    }

    return Material(
      color: Colors.transparent,
      borderRadius: widget.borderRadius,
      child: InkWell(
        borderRadius: widget.borderRadius,
        onTap: canInteract ? () => changeValue(!selected) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedOpacity(
              opacity: canInteract ? 1.0 : 0.5,
              duration: const Duration(milliseconds: 150),
              child: Row(
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (widget.title != null) widget.title!, if (widget.subtitle != null) widget.subtitle!]),
                  ),
                  Switch(value: selected, onChanged: canInteract ? changeValue : null),
                ],
              ),
            ),
            AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: progressBar),
          ],
        ),
      ),
    );
  }
}
