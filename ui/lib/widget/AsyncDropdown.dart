import 'dart:math';

import 'package:flutter/material.dart';

import 'AsyncWidget.dart';

typedef DropdownItemBuilder = Widget Function(String item);

class AsyncDropdown extends AsyncWidget<String, AsyncDropdown> {
  final String? label;
  final DropdownItemBuilder? itemEndBuilder;
  final DropdownItemBuilder? itemBeginBuilder;
  final DropdownItemBuilder? itemBuilder;
  final String searchHint;

  const AsyncDropdown({
    super.key,
    this.label,
    this.searchHint = "搜索 (支持正则表达式)",
    this.itemEndBuilder,
    this.itemBeginBuilder,
    this.itemBuilder,
    super.defaultValue,
    super.getter,
    super.setter,
    super.itemsGetter,
    super.errorHandler,
    super.timeoutTime,
    super.showDefaultError,
    super.progressNotifier,
    super.readOnlyNotifier,
  });

  @override
  AsyncDropdown copyWith({
    String? defaultValue,
    AsyncValueGetter<String>? getter,
    AsyncValueSetter<String>? setter,
    ErrorCallback? errorHandler,
    Duration? timeout,
    bool? showDefaultError,
    AsyncDrawer<String>? drawer,
    AsyncItemsGetter<String>? itemsGetter,
    ValueNotifier<double>? progressNotifier,
    ValueNotifier<bool>? readOnlyNotifier,
  }) {
    return AsyncDropdown(
      key: key,
      label: label,
      searchHint: searchHint,
      defaultValue: defaultValue ?? this.defaultValue,
      getter: getter ?? this.getter,
      setter: setter ?? this.setter,
      itemsGetter: itemsGetter ?? this.itemsGetter,
      errorHandler: errorHandler ?? this.errorHandler,
      timeoutTime: timeout ?? timeoutTime,
      showDefaultError: showDefaultError ?? this.showDefaultError,
      progressNotifier: progressNotifier ?? this.progressNotifier,
      readOnlyNotifier: readOnlyNotifier ?? this.readOnlyNotifier,
      itemEndBuilder: itemEndBuilder,
      itemBeginBuilder: itemBeginBuilder,
      itemBuilder: itemBuilder,
    );
  }

  @override
  State<AsyncDropdown> createState() => _AsyncDropdownState();
}

class _AsyncDropdownState extends AsyncWidgetState<String, AsyncDropdown> with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _displayController = TextEditingController();
  OverlayEntry? _overlay;

  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<double> _scale;

  List<String> _items = [];
  List<String> _filtered = [];

  bool _openUp = false;

  static const double _dropdownGap = 6;
  static const double _itemHeight = 40;
  static const double _searchHeight = 56;
  static const double _maxHeight = 320;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _scale = Tween(begin: 0.95, end: 1.0).animate(_fade);
    _searchController.addListener(_filter);
  }

  void _filter() {
    final text = _searchController.text.trim();
    if (text.isEmpty) {
      _filtered = List.from(_items);
    } else {
      try {
        final reg = RegExp(text, caseSensitive: false);
        _filtered = _items.where((e) => reg.hasMatch(e)).toList();
      } catch (_) {
        _filtered = [];
      }
    }
    _overlay?.markNeedsBuild();
  }

  double _calcHeight() {
    final h = _searchHeight + _filtered.length * _itemHeight;
    return min(_maxHeight, h);
  }

  void _open(List<String> items) {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    _items = items;
    _filtered = List.from(items);
    final dropdownHeight = _calcHeight();
    final spaceBelow = screenHeight - offset.dy - size.height;
    final spaceAbove = offset.dy;
    _openUp = spaceBelow < dropdownHeight && spaceAbove > spaceBelow;
    final offsetY = _openUp ? -(dropdownHeight + _dropdownGap) : size.height + _dropdownGap;
    _overlay = OverlayEntry(
      builder: (context) {
        final width = size.width;
        return Positioned.fill(
          child: GestureDetector(
            onTap: close,
            behavior: HitTestBehavior.translucent,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(onTap: close, behavior: HitTestBehavior.opaque),
                ),
                CompositedTransformFollower(
                  link: _layerLink,
                  offset: Offset(0, offsetY),
                  child: FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      alignment: _openUp ? Alignment.bottomCenter : Alignment.topCenter,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(5),
                        clipBehavior: Clip.antiAlias,
                        child: SizedBox(
                          width: width,
                          height: _calcHeight(),
                          child: Column(
                            children: [
                              SizedBox(
                                height: _searchHeight,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: TextField(
                                    controller: _searchController,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.search),
                                      hintText: widget.searchHint,
                                      suffixIcon: _searchController.text.isEmpty
                                          ? null
                                          : IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: () {
                                                _searchController.clear();
                                              },
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Material(
                                  type: MaterialType.transparency,
                                  child: ScrollConfiguration(
                                    behavior: const ScrollBehavior().copyWith(scrollbars: true),
                                    child: ListView.builder(
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: _filtered.length,
                                      itemBuilder: (context, i) {
                                        final item = _filtered[i];
                                        return InkWell(
                                          onTap: () {
                                            changeValue(item);
                                            close();
                                          },
                                          child: SizedBox(
                                            height: _itemHeight,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              child: Row(
                                                children: [
                                                  ?widget.itemBeginBuilder?.call(item),
                                                  Expanded(
                                                    child: widget.itemBuilder?.call(item) ?? Baseline(baseline: 16, baselineType: TextBaseline.alphabetic, child: Text(item)),
                                                  ),
                                                  ?widget.itemEndBuilder?.call(item),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_overlay!);
    _anim.forward();
    setState(() {});
  }

  void close() {
    if (_overlay == null) return;
    _anim.reverse().then((_) {
      _overlay?.remove();
      _overlay = null;
      _searchController.clear();
      _focusNode.unfocus();
      if (mounted) setState(() {});
    });
  }

  @override
  Widget buildContent(BuildContext context, String? value, bool busy, double? progress, List<String>? items) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (value != null && _displayController.text != value) {
      _displayController.text = value;
    }

    final decorationWidget = value == null ? null : widget.itemEndBuilder?.call(value);
    final beginWidget = value == null ? null : widget.itemBeginBuilder?.call(value);

    return IgnorePointer(
      ignoring: busy,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: AnimatedOpacity(
          opacity: busy ? 0.6 : 1,
          duration: const Duration(milliseconds: 120),
          child: TextField(
            controller: _displayController,
            readOnly: true,
            focusNode: _focusNode,
            style: TextStyle(fontSize: 14),
            onTap: () {
              if (_overlay == null) {
                _open(items ?? []);
              } else {
                close();
              }
            },
            decoration: InputDecoration(
              labelText: widget.label,
              filled: true,
              fillColor: colorScheme.surface,
              prefixIcon: beginWidget == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(left: 8, right: 4),
                      child: SizedBox(height: 40, child: beginWidget),
                    ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (decorationWidget != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 1),
                        child: SizedBox(height: 40, child: decorationWidget),
                      ),
                    busy
                        ? Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 3, value: progress, valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary)),
                            ),
                          )
                        : AnimatedRotation(
                            turns: _overlay != null ? 0.5 : 0,
                            duration: const Duration(milliseconds: 120),
                            child: SizedBox(height: 40, width: 32, child: const Icon(Icons.arrow_drop_down)),
                          ),
                  ],
                ),
              ),
              border: const UnderlineInputBorder(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
