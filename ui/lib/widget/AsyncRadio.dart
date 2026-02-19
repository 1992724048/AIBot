import 'dart:async';

import 'package:flutter/material.dart';

typedef AsyncValueSetter<T> = Future<bool> Function(T value);
typedef AsyncValueGetter<T> = Future<T> Function();
typedef ErrorCallback = void Function(Object error, StackTrace? stack);

class AsyncRadio<T> extends StatefulWidget {
  final T value;
  final dynamic selected;
  final T defaultSelected;
  final AsyncValueSetter<T> onSelected;
  final Duration timeout;
  final ErrorCallback? onError;

  final Widget? title;
  final Widget? subtitle;

  const AsyncRadio({
    super.key,
    required this.value,
    required this.defaultSelected,
    required this.onSelected,
    this.selected,
    this.timeout = const Duration(seconds: 10),
    this.onError,
    this.title,
    this.subtitle,
  });

  @override
  State<AsyncRadio<T>> createState() => _AsyncRadioState<T>();
}

class _AsyncRadioState<T> extends State<AsyncRadio<T>> {
  late T _groupValue;
  bool _loading = false;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _groupValue = widget.defaultSelected;
    _initSelected();
  }

  @override
  void didUpdateWidget(covariant AsyncRadio<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_loading || _initializing) return;

    if (widget.selected is T && widget.selected != oldWidget.selected) {
      _groupValue = widget.selected as T;
    }
  }

  Future<void> _initSelected() async {
    final val = widget.selected;

    if (val == null) {
      _groupValue = widget.defaultSelected;
      _initializing = false;
      return;
    }

    if (val is T) {
      _groupValue = val;
      _initializing = false;
      return;
    }

    if (val is AsyncValueGetter<T>) {
      try {
        _groupValue = await val().timeout(widget.timeout);
      } on TimeoutException catch (e, s) {
        _handleError(e, s);
        _groupValue = widget.defaultSelected;
      } catch (e, s) {
        _handleError(e, s);
        _groupValue = widget.defaultSelected;
      } finally {
        if (mounted) setState(() => _initializing = false);
      }
      return;
    }

    throw ArgumentError('selected 必须是 T / AsyncValueGetter<T> / null');
  }

  Future<void> _handleSelect() async {
    if (_loading || _initializing) return;
    if (_groupValue == widget.value) return;

    final oldValue = _groupValue;
    setState(() => _loading = true);

    try {
      final ok = await widget.onSelected(widget.value).timeout(widget.timeout);
      if (!ok) throw StateError('操作被拒绝');
      if (mounted) setState(() => _groupValue = widget.value);
    } on TimeoutException catch (e, s) {
      _handleError(e, s);
      _groupValue = oldValue;
    } catch (e, s) {
      _handleError(e, s);
      _groupValue = oldValue;
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

    return RadioListTile<T>(
      title: widget.title,
      subtitle: widget.subtitle,
      value: widget.value,
      groupValue: _groupValue,
      onChanged: busy ? null : (_) => _handleSelect(),
      secondary: busy ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : null,
    );
  }
}
