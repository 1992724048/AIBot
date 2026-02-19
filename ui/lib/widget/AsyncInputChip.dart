import 'dart:async';

import 'package:flutter/material.dart';

typedef AsyncSelectedSetter = Future<bool> Function(bool selected);
typedef AsyncSelectedGetter = Future<bool> Function();
typedef ErrorCallback = void Function(Object error, StackTrace? stack);

class AsyncInputChip extends StatefulWidget {
  final Widget label;
  final Widget? avatar;
  final String? tooltip;
  final dynamic selected;
  final bool defaultSelected;
  final AsyncSelectedSetter onSelected;
  final Duration timeout;
  final Color? selectedColor;
  final ErrorCallback? onError;

  const AsyncInputChip({
    super.key,
    required this.label,
    required this.onSelected,
    this.selected,
    this.defaultSelected = false,
    this.avatar,
    this.tooltip,
    this.selectedColor,
    this.timeout = const Duration(seconds: 10),
    this.onError,
  });

  @override
  State<AsyncInputChip> createState() => _AsyncInputChipState();
}

class _AsyncInputChipState extends State<AsyncInputChip> {
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
  void didUpdateWidget(covariant AsyncInputChip oldWidget) {
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
      setState(() => _initializing = true);
      try {
        _selected = await val().timeout(widget.timeout);
      } on TimeoutException catch (e, s) {
        _handleError(e, s);
        _selected = widget.defaultSelected;
      } catch (e, s) {
        _handleError(e, s);
        _selected = widget.defaultSelected;
      } finally {
        if (mounted) {
          setState(() => _initializing = false);
        }
      }
      return;
    }

    throw ArgumentError('selected 必须是 bool / AsyncSelectedGetter / null，当前是 $val');
  }

  Future<void> _handleSelected(bool value) async {
    if (_loading || _initializing) return;

    bool oldValue = _selected;
    setState(() => _loading = true);

    try {
      final success = await widget.onSelected(value).timeout(widget.timeout);
      if (!success) {
        throw StateError('操作被拒绝');
      }
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
          SnackBar(showCloseIcon: true, duration: const Duration(seconds: 2), content: Text('操作失败: $error')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading || _initializing;

    return InputChip(
      tooltip: widget.tooltip,
      showCheckmark: widget.avatar == null,
      selected: _selected,
      selectedColor: widget.selectedColor,
      avatar: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: busy
            ? const SizedBox.square(
                key: ValueKey('loading'),
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : widget.avatar == null
            ? const SizedBox.shrink(key: ValueKey('empty'))
            : SizedBox(
                key: const ValueKey('icon'),
                width: 18,
                height: 18,
                child: Center(child: widget.avatar),
              ),
      ),
      label: widget.label,
      onSelected: busy ? null : _handleSelected,
    );
  }
}
