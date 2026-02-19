import 'dart:async';

import 'package:flutter/material.dart';

typedef ErrorCallback = void Function(Object error, StackTrace? stack);
typedef AsyncDoubleSetter = Future<bool> Function(double value);
typedef AsyncDoubleGetter = Future<double> Function();

class AsyncSlider extends StatefulWidget {
  final double min;
  final double max;
  final int? divisions;

  final dynamic selected;
  final double defaultSelected;
  final AsyncDoubleSetter onSelected;
  final Duration timeout;
  final ErrorCallback? onError;

  final String Function(double value)? labelBuilder;

  const AsyncSlider({
    super.key,
    required this.min,
    required this.max,
    required this.defaultSelected,
    required this.onSelected,
    this.selected,
    this.divisions,
    this.timeout = const Duration(seconds: 10),
    this.onError,
    this.labelBuilder,
  });

  @override
  State<AsyncSlider> createState() => _AsyncSliderState();
}

class _AsyncSliderState extends State<AsyncSlider> {
  late double _value;
  late double _committedValue;
  bool _loading = false;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _value = widget.defaultSelected;
    _committedValue = widget.defaultSelected;
    _initSelected();
  }

  @override
  void didUpdateWidget(covariant AsyncSlider oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_loading || _initializing) return;

    if (widget.selected is double && widget.selected != oldWidget.selected) {
      _value = widget.selected as double;
      _committedValue = _value;
    }
  }

  Future<void> _initSelected() async {
    final val = widget.selected;

    if (val == null) {
      _value = widget.defaultSelected;
      _committedValue = _value;
      _initializing = false;
      return;
    }

    if (val is double) {
      _value = val;
      _committedValue = val;
      _initializing = false;
      return;
    }

    if (val is AsyncDoubleGetter) {
      try {
        _value = await val().timeout(widget.timeout);
        _committedValue = _value;
      } on TimeoutException catch (e, s) {
        _handleError(e, s);
        _value = widget.defaultSelected;
        _committedValue = _value;
      } catch (e, s) {
        _handleError(e, s);
        _value = widget.defaultSelected;
        _committedValue = _value;
      } finally {
        if (mounted) setState(() => _initializing = false);
      }
      return;
    }

    throw ArgumentError('selected 必须是 double / AsyncDoubleGetter / null');
  }

  Future<void> _commit(double value) async {
    if (_loading || _initializing) return;

    final oldValue = _committedValue;
    setState(() => _loading = true);

    try {
      final ok = await widget.onSelected(value).timeout(widget.timeout);
      if (!ok) throw StateError('操作被拒绝');
      _committedValue = value;
    } on TimeoutException catch (e, s) {
      _handleError(e, s);
      _value = oldValue;
    } catch (e, s) {
      _handleError(e, s);
      _value = oldValue;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Slider(
          value: _value,
          min: widget.min,
          max: widget.max,
          divisions: widget.divisions,
          label: widget.labelBuilder?.call(_value),
          onChanged: busy ? null : (v) => setState(() => _value = v),
          onChangeEnd: busy ? null : _commit,
        ),
        if (busy)
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      ],
    );
  }
}
