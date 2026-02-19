import 'dart:async';

import 'package:flutter/material.dart';

typedef AsyncSelectedSetter = Future<bool> Function(bool selected);
typedef AsyncSelectedGetter = Future<bool> Function();
typedef ErrorCallback = void Function(Object error, StackTrace? stack);

class AsyncCheckbox extends StatefulWidget {
  final dynamic selected;
  final bool defaultSelected;
  final AsyncSelectedSetter onSelected;
  final Duration timeout;
  final ErrorCallback? onError;
  final BorderRadius borderRadius;

  final Widget? title;
  final Widget? subtitle;
  final bool dense;
  final ListTileControlAffinity controlAffinity;

  const AsyncCheckbox({
    super.key,
    required this.onSelected,
    this.selected,
    this.defaultSelected = false,
    this.timeout = const Duration(seconds: 10),
    this.onError,
    this.title,
    this.subtitle,
    this.dense = false,
    this.controlAffinity = ListTileControlAffinity.leading,
    this.borderRadius = const BorderRadius.all(Radius.circular(5)),
  });

  @override
  State<AsyncCheckbox> createState() => _AsyncCheckboxState();
}

class _AsyncCheckboxState extends State<AsyncCheckbox> {
  late bool _selected;
  bool _loading = false;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _selected = false;
    _initSelected();
  }

  @override
  void didUpdateWidget(covariant AsyncCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_loading || _initializing) return;

    if (widget.selected is bool && widget.selected != oldWidget.selected) {
      _selected = widget.selected as bool;
    }
  }

  Future<void> _initSelected() async {
    final val = widget.selected;

    if (val == null) {
      _selected = widget.defaultSelected;
      _initializing = false;
      return;
    }

    if (val is bool) {
      _selected = val;
      _initializing = false;
      return;
    }

    if (val is AsyncSelectedGetter) {
      try {
        _selected = await val().timeout(widget.timeout);
      } on TimeoutException catch (e, s) {
        _handleError(e, s);
        _selected = widget.defaultSelected;
      } catch (e, s) {
        _handleError(e, s);
        _selected = widget.defaultSelected;
      } finally {
        if (mounted) setState(() => _initializing = false);
      }
      return;
    }

    throw ArgumentError('selected 必须是 bool / AsyncSelectedGetter / null');
  }

  Future<void> _handleChange(bool? value) async {
    if (value == null || _loading || _initializing) return;

    final oldValue = _selected;
    setState(() => _loading = true);

    try {
      final ok = await widget.onSelected(value).timeout(widget.timeout);
      if (!ok) throw StateError('操作被拒绝');
      if (mounted) setState(() => _selected = value);
    } on TimeoutException catch (e, s) {
      _handleError(e, s);
      _selected = oldValue;
    } catch (e, s) {
      _handleError(e, s);
      _selected = oldValue;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleError(Object error, [StackTrace? stack]) {
    if (widget.onError != null) {
      widget.onError!(error, stack);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $error'), duration: const Duration(seconds: 2), showCloseIcon: true),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading || _initializing;

    return Material(
      color: Colors.transparent,
      borderRadius: widget.borderRadius,
      child: InkWell(
        borderRadius: widget.borderRadius,
        onTap: busy ? null : () => _handleChange(!_selected),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: busy
                        ? const SizedBox.square(
                            key: ValueKey('loading'),
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Checkbox(
                            key: const ValueKey('checkbox'),
                            value: _selected,
                            onChanged: busy ? null : _handleChange,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.title != null) widget.title!,
                    if (widget.subtitle != null)
                      Padding(padding: const EdgeInsets.only(top: 0), child: widget.subtitle!),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
