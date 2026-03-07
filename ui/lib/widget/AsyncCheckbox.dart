import 'package:flutter/material.dart';

import 'AsyncWidget.dart';

class AsyncCheckbox extends AsyncWidget<bool, AsyncCheckbox> {
  const AsyncCheckbox({
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
  });

  final Widget? title;

  @override
  AsyncCheckbox copyWith({
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
    return AsyncCheckbox(
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
    );
  }

  @override
  State<AsyncCheckbox> createState() => _AsyncCheckboxState();
}

class _AsyncCheckboxState extends AsyncWidgetState<bool, AsyncCheckbox> {
  @override
  Widget buildContent(BuildContext context, bool? value, bool busy, double? progress, List<bool>? items) {
    final selected = value ?? false;
    final canInteract = !busy && !readOnly && widget.setter != null;
    final hasProgress = progress != null && progress != -1;

    Widget checkbox = SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!hasProgress && !busy)
            Checkbox(value: selected, onChanged: canInteract ? (v) => changeValue(v!) : null, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact),
          if (hasProgress)
            IgnorePointer(
              child: SizedBox.square(dimension: 16, child: CircularProgressIndicator(value: progress, strokeWidth: 2)),
            )
          else if (busy)
            const IgnorePointer(child: SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))),
        ],
      ),
    );

    if (widget.title == null) {
      return checkbox;
    }

    return InkWell(
      onTap: canInteract ? () => changeValue(!selected) : null,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            checkbox,
            const SizedBox(width: 8),
            Expanded(child: widget.title!),
          ],
        ),
      ),
    );
  }
}
