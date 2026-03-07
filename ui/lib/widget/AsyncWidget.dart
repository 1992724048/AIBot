import 'package:flutter/material.dart';

typedef AsyncValueGetter<T> = Future<T> Function();
typedef AsyncValueSetter<T> = Future<bool> Function(T value);
typedef AsyncItemsGetter<T> = Future<List<T>> Function();
typedef AsyncDrawer<T> = Widget Function(Future<void> Function(T newValue) change, BuildContext context, T? value, bool busy, double? progress, List<T>? items);
typedef ErrorCallback = void Function(Object error, StackTrace? stack);

abstract class AsyncWidget<T, W extends AsyncWidget<T, W>> extends StatefulWidget {
  final T? defaultValue;
  final AsyncValueGetter<T>? getter;
  final AsyncValueSetter<T>? setter;
  final ErrorCallback? errorHandler;
  final Duration timeoutTime;
  final bool showDefaultError;
  final AsyncDrawer<T>? drawer;
  final AsyncItemsGetter<T>? itemsGetter;
  final ValueNotifier<double>? progressNotifier;
  final ValueNotifier<bool>? readOnlyNotifier;

  const AsyncWidget({
    super.key,
    this.defaultValue,
    this.getter,
    this.setter,
    this.errorHandler,
    this.timeoutTime = const Duration(seconds: 10),
    this.showDefaultError = true,
    this.drawer,
    this.itemsGetter,
    this.progressNotifier,
    this.readOnlyNotifier,
  });

  W copyWith({
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
  });

  W get(AsyncValueGetter<T> getter) => copyWith(getter: getter);

  W set(AsyncValueSetter<T> setter) => copyWith(setter: setter);

  W error(ErrorCallback handler) => copyWith(errorHandler: handler);

  W draw(AsyncDrawer<T> drawer) => copyWith(drawer: drawer);

  W process(ValueNotifier<double> notifier) => copyWith(progressNotifier: notifier);

  W readOnly(ValueNotifier<bool> notifier) => copyWith(readOnlyNotifier: notifier);

  W items(AsyncItemsGetter<T> getter) => copyWith(itemsGetter: getter);
  
  W timeout(Duration timeout) => copyWith(timeout: timeout);

  W withDefault(T value) => copyWith(defaultValue: value);
}

abstract class AsyncWidgetState<T, W extends AsyncWidget<T, W>> extends State<W> {
  late T? value;
  late List<T>? items;

  bool initializing = true;
  bool loading = false;
  bool itemsLoading = false;

  bool get readOnly => widget.readOnlyNotifier?.value ?? false;

  double? get progress {
    final p = widget.progressNotifier?.value;
    return p?.clamp(-1.0, 1.0);
  }

  bool get busy => initializing || loading || itemsLoading || (progress != null && progress != -1);

  @override
  void initState() {
    super.initState();
    value = widget.defaultValue;
    items = null;
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      if (widget.itemsGetter != null) {
        setState(() => itemsLoading = true);
        items = await widget.itemsGetter!().timeout(widget.timeoutTime);
        setState(() => itemsLoading = false);
      }

      if (widget.getter != null) {
        value = await widget.getter!().timeout(widget.timeoutTime);
      }
    } catch (e, s) {
      _handleError(e, s);
      value = widget.defaultValue;
    } finally {
      if (mounted) {
        setState(() => initializing = false);
      }
    }
  }

  Future<void> changeValue(T newValue) async {
    if (busy || readOnly || widget.setter == null) return;

    final old = value;

    setState(() {
      loading = true;
      value = newValue;
    });

    try {
      final ok = await widget.setter!(newValue).timeout(widget.timeoutTime);
      if (!ok) throw StateError("已被拒绝");
    } catch (e, s) {
      _handleError(e, s);
      value = old;
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _handleError(Object error, StackTrace? stack) {
    if (widget.errorHandler != null) {
      widget.errorHandler!(error, stack);
      return;
    }

    if (!widget.showDefaultError) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("操作失败: $error"), duration: const Duration(seconds: 2), showCloseIcon: true));
    });
  }

  Widget buildContent(BuildContext context, T? value, bool busy, double? progress, List<T>? items);

  @override
  Widget build(BuildContext context) {
    Widget builder(double? progress, bool readOnly) {
      if (widget.drawer != null) {
        return widget.drawer!(changeValue, context, value, busy, progress, items);
      }
      return buildContent(context, value, busy, progress, items);
    }

    final progressNotifier = widget.progressNotifier;
    final readOnlyNotifier = widget.readOnlyNotifier;

    if (progressNotifier == null && readOnlyNotifier == null) {
      return builder(null, false);
    }

    Widget child = builder(progressNotifier?.value, readOnlyNotifier?.value ?? false);

    if (progressNotifier != null) {
      child = ValueListenableBuilder<double>(
        valueListenable: progressNotifier,
        builder: (_, p, _) {
          return builder(p, readOnlyNotifier?.value ?? false);
        },
      );
    }

    if (readOnlyNotifier != null) {
      child = ValueListenableBuilder<bool>(
        valueListenable: readOnlyNotifier,
        builder: (_, r, _) {
          return builder(progressNotifier?.value, r);
        },
      );
    }

    return child;
  }
}

abstract class AsyncActionWidget<W extends AsyncActionWidget<W>> extends StatefulWidget {
  final Future<bool> Function()? action_;
  final ErrorCallback? errorHandler;
  final Duration timeout;
  final ValueNotifier<double>? progressNotifier;
  final ValueNotifier<bool>? readOnlyNotifier;

  const AsyncActionWidget({super.key, this.action_, this.errorHandler, this.timeout = const Duration(seconds: 10), this.progressNotifier, this.readOnlyNotifier});

  W copyWith({Future<bool> Function()? action_, ErrorCallback? errorHandler, Duration? timeout, ValueNotifier<double>? progressNotifier, ValueNotifier<bool>? readOnlyNotifier});

  W action(Future<bool> Function() fn) => copyWith(action_: fn);

  W error(ErrorCallback handler) => copyWith(errorHandler: handler);

  W process(ValueNotifier<double> notifier) => copyWith(progressNotifier: notifier);

  W readOnly(ValueNotifier<bool> notifier) => copyWith(readOnlyNotifier: notifier);
}

abstract class AsyncActionWidgetState<W extends AsyncActionWidget<W>> extends State<W> {
  bool running = false;

  bool get readOnly => widget.readOnlyNotifier?.value ?? false;

  double? get progress {
    final p = widget.progressNotifier?.value;
    return p?.clamp(-1.0, 1.0);
  }

  bool get busy => running || (progress != null && progress != -1);

  Future<void> execute() async {
    if (busy || readOnly) return;
    if (widget.action_ == null) return;

    setState(() => running = true);

    try {
      final ok = await widget.action_!().timeout(widget.timeout);
      if (!ok) throw StateError("操作失败");
    } catch (e, s) {
      _handleError(e, s);
    } finally {
      if (mounted) {
        setState(() => running = false);
      }
    }
  }

  void _handleError(Object error, StackTrace? stack) {
    if (widget.errorHandler != null) {
      widget.errorHandler!(error, stack);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("操作失败: $error"), duration: const Duration(seconds: 2), showCloseIcon: true));
    });
  }

  Widget buildContent(BuildContext context, bool busy, double? progress);

  @override
  Widget build(BuildContext context) {
    Widget builder(double? progress, bool readOnly) {
      final isBusy = running || (progress != null && progress != -1);

      return buildContent(context, isBusy, progress);
    }

    final progressNotifier = widget.progressNotifier;
    final readOnlyNotifier = widget.readOnlyNotifier;

    if (progressNotifier == null && readOnlyNotifier == null) {
      return builder(progress, readOnly);
    }

    Widget child = builder(progressNotifier?.value, readOnlyNotifier?.value ?? false);

    if (progressNotifier != null) {
      child = ValueListenableBuilder<double>(
        valueListenable: progressNotifier,
        builder: (_, p, __) {
          return builder(p, readOnlyNotifier?.value ?? false);
        },
      );
    }

    if (readOnlyNotifier != null) {
      child = ValueListenableBuilder<bool>(
        valueListenable: readOnlyNotifier,
        builder: (_, r, __) {
          return builder(progressNotifier?.value, r);
        },
      );
    }

    return child;
  }
}
