import 'dart:async';

import 'package:flutter/material.dart';

typedef AsyncValueGetter<T> = Future<T> Function();
typedef AsyncValueSetter<T> = Future<bool> Function(T value);
typedef ErrorCallback = void Function(Object error, StackTrace? stack);
typedef DropdownItemBuilder = Widget Function(String item);

class AsyncDropdown extends StatefulWidget {
  final String label;
  final dynamic value;
  final dynamic items;
  final String? defaultValue;
  final AsyncValueSetter<String> onChanged;
  final Duration timeout;
  final ErrorCallback? onError;
  final DropdownItemBuilder? itemBuilder;

  const AsyncDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.defaultValue,
    this.timeout = const Duration(days: 1),
    this.onError,
    this.itemBuilder,
  });

  @override
  State<AsyncDropdown> createState() => _AsyncDropdownState();
}

class _AsyncDropdownState extends State<AsyncDropdown> {
  List<String> _items = [];
  String? _value;

  bool _loadingItems = false;
  bool _loadingValue = false;
  bool _saving = false;

  bool get _busy => _loadingItems || _loadingValue || _saving;

  @override
  void initState() {
    super.initState();
    _initItems();
    _initValue();
  }

  Future<void> _initItems() async {
    final src = widget.items;

    if (src is List<String>) {
      _items = src;
      return;
    }

    if (src is AsyncValueGetter<List<String>>) {
      setState(() => _loadingItems = true);
      try {
        _items = await src().timeout(widget.timeout);
      } catch (e, s) {
        _handleError(e, s);
        _items = [];
      } finally {
        if (mounted) setState(() => _loadingItems = false);
      }
    }
  }

  Future<void> _initValue() async {
    final val = widget.value;

    if (val == null) {
      _value = widget.defaultValue;
      return;
    }

    if (val is String) {
      _value = val;
      return;
    }

    if (val is AsyncValueGetter<String>) {
      setState(() => _loadingValue = true);
      try {
        _value = await val().timeout(widget.timeout);
      } catch (e, s) {
        _handleError(e, s);
        _value = widget.defaultValue;
      } finally {
        if (mounted) setState(() => _loadingValue = false);
      }
    }
  }

  Future<void> _handleChanged(String newValue) async {
    if (_busy) return;

    final old = _value;
    if (newValue == old) {
      return;
    }

    setState(() {
      _saving = true;
      _value = newValue;
    });

    try {
      final ok = await widget.onChanged(newValue).timeout(widget.timeout);
      if (!ok) throw StateError('操作被拒绝');
    } catch (e, s) {
      _handleError(e, s);
      _value = old;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _handleError(Object error, [StackTrace? stack]) {
    if (widget.onError != null) {
      widget.onError!(error, stack);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(showCloseIcon: true, duration: const Duration(seconds: 2), content: Text('操作失败: $error')));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    Widget buildItem(String item) {
      final child = widget.itemBuilder?.call(item) ?? Text(item);
      return Align(alignment: Alignment.centerLeft, child: child);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              alignment: Alignment.center,
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _value,
                  items: _items
                      .map(
                        (e) => DropdownMenuItem<String>(
                          value: e,
                          child: SizedBox(width: constraints.maxWidth, child: buildItem(e)),
                        ),
                      )
                      .toList(),
                  onChanged: _busy ? null : (v) => _handleChanged(v!),
                  style: textTheme.bodyMedium,
                  dropdownColor: colorScheme.surface,
                  icon: Icon(Icons.arrow_drop_down, color: colorScheme.primary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: colorScheme.surface,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: colorScheme.primary, width: 2),
                    ),
                  ),
                ),
                if (_busy)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
