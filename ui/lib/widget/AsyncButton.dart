import 'dart:async';

import 'package:flutter/material.dart';

enum AsyncButtonType { elevated, outlined, text }

class AsyncButton extends StatefulWidget {
  final Future<bool> Function() onPressed;
  final void Function(Object error, StackTrace? stack)? onError;
  final Widget child;
  final AsyncButtonType type;
  final ButtonStyle? style;
  final double loadingIndicatorSize;
  final Duration timeout;

  const AsyncButton({
    super.key,
    required this.onPressed,
    this.onError,
    required this.child,
    this.type = AsyncButtonType.elevated,
    this.style,
    this.loadingIndicatorSize = 18,
    this.timeout = const Duration(seconds: 10),
  });

  @override
  State<AsyncButton> createState() => _AsyncButtonState();
}

class _AsyncButtonState extends State<AsyncButton> {
  bool _running = false;

  Future<void> _handle() async {
    if (_running) return;
    setState(() => _running = true);

    try {
      final success = await widget.onPressed().timeout(widget.timeout, onTimeout: () => false);
      if (!success && mounted) _show('操作失败');
    } on TimeoutException catch (e, s) {
      _handleError(e, s);
    } catch (e, s) {
      _handleError(e, s);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  void _handleError(Object e, StackTrace? s) {
    final onError = widget.onError;
    if (onError != null) {
      onError(e, s);
    } else {
      _show('出错了：$e');
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2), showCloseIcon: true));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style =
        widget.style ??
        (widget.type == AsyncButtonType.elevated
            ? ElevatedButton.styleFrom()
            : widget.type == AsyncButtonType.text
            ? TextButton.styleFrom()
            : OutlinedButton.styleFrom());

    Widget content = AnimatedSwitcher(
      duration: Duration(microseconds: 200),
      child: _running
          ? SizedBox.square(
              dimension: widget.loadingIndicatorSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: style.foregroundColor?.resolve({.disabled}) ?? theme.colorScheme.onPrimary,
              ),
            )
          : widget.child,
    );

    switch (widget.type) {
      case AsyncButtonType.elevated:
        return ElevatedButton(onPressed: _running ? null : _handle, style: style, child: content);
      case AsyncButtonType.text:
        return TextButton(onPressed: _running ? null : _handle, style: style, child: content);
      case AsyncButtonType.outlined:
        return OutlinedButton(onPressed: _running ? null : _handle, style: style, child: content);
    }
  }
}
