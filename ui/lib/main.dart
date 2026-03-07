import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:ui/pages/AboutPage.dart';
import 'package:ui/pages/BackendPage.dart';
import 'package:ui/pages/ControlPage.dart';
import 'package:ui/pages/ModelPage.dart';
import 'package:ui/pages/PreviewPage.dart';
import 'package:window_manager/window_manager.dart';

import 'ffi.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1120, 680),
    minimumSize: Size(1120, 680),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  MainApp({super.key});

  final _refreshNotifier = ValueNotifier<int>(0);

  ButtonStyle appElevatedButtonStyle(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ElevatedButton.styleFrom(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      elevation: 0,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final elevatedButtonStyle = ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    );

    final textButtonStyle = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    );

    final outlinedButtonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    );

    ThemeData buildTheme(Brightness brightness, Color seedColor) => ThemeData(
      useMaterial3: true,
      brightness: brightness,
      textTheme: ThemeData(brightness: brightness).textTheme.apply(fontFamily: 'zh'),
      colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness),
      elevatedButtonTheme: ElevatedButtonThemeData(style: elevatedButtonStyle),
      textButtonTheme: TextButtonThemeData(style: textButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedButtonStyle),
    );

    return ValueListenableBuilder<int>(
      valueListenable: _refreshNotifier,
      builder: (context, value, child) {
        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            Color systemColor = Colors.blue;

            if (lightDynamic != null) {
              systemColor = lightDynamic.primary;
            }

            return MaterialApp(
              themeMode: ThemeMode.system,
              theme: buildTheme(Brightness.light, systemColor),
              darkTheme: buildTheme(Brightness.dark, systemColor),
              home: const HomePage(),
              builder: (context, child) {
                return AnimatedTheme(data: Theme.of(context), duration: const Duration(milliseconds: 10), curve: Curves.easeInOut, child: child!);
              },
            );
          },
        );
      },
    );
  }
}

const List<_NavItem> _navIcons = [
  _NavItem(Icons.remove_red_eye_outlined, Icons.remove_red_eye, "画面"),
  _NavItem(Icons.assistant_outlined, Icons.assistant, "模型"),
  _NavItem(Icons.dashboard_customize_sharp, Icons.dashboard, "后端"),
  _NavItem(Icons.open_with_outlined, Icons.control_camera, "操作"),
  _NavItem(Icons.info_outlined, Icons.info, "关于"),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final PageController _ctrl = PageController(initialPage: _navIcons.length - 1);
  final List<Widget> _pages = const [PreviewPage(), ModelPage(), BackendPage(), ControlPage(), AboutPage()];

  int _targetPage = _navIcons.length - 1;
  bool alwaysTop = false;

  @override
  void initState() {
    super.initState();
  }

  void _switchPage(int i) {
    _targetPage = i;
    _ctrl.animateToPage(i, duration: const Duration(milliseconds: 500), curve: Curves.easeOutQuart);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Listener(
                  onPointerDown: (_) => windowManager.startDragging(),
                  child: Container(color: Colors.transparent),
                ),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_TitleWidget(), _PageCtr(), _ToolButton()]),
            ],
          ),
          Divider(thickness: 1, height: 1),
          Expanded(
            child: PageView(controller: _ctrl, physics: const NeverScrollableScrollPhysics(), onPageChanged: (i) => setState(() {}), children: _pages),
          ),
        ],
      ),
    );
  }

  Widget _ToolButton() {
    return SizedBox(
      width: 279,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: .end,
          mainAxisAlignment: .end,
          children: [
            Row(
              children: [
                const SizedBox(width: 3),
                IconButton(onPressed: () {}, icon: const Icon(Icons.group_add_outlined, size: 20)),
                const VerticalDivider(thickness: 1, indent: 8, endIndent: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      alwaysTop = !alwaysTop;
                      windowManager.setAlwaysOnTop(alwaysTop);
                    });
                  },
                  icon: Icon(alwaysTop ? Icons.push_pin : Icons.push_pin_outlined, size: 20),
                ),
                const SizedBox(width: 3),
                IconButton(
                  onPressed: () {
                    windowManager.minimize();
                  },
                  icon: Icon(Icons.remove, size: 20),
                ),
                const SizedBox(width: 3),
                IconButton(
                  onPressed: () async {
                    bool shouldClose = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('确认关闭'),
                        content: Text('确定要退出应用吗？'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('取消')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('确定')),
                        ],
                      ),
                    );

                    if (shouldClose) {
                      await FFI.invoke('stop_monitor');
                      await windowManager.destroy();
                    }
                  },
                  icon: Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(width: 7),
          ],
        ),
      ),
    );
  }

  Widget _PageCtr() {
    return Expanded(
      child: Center(
        child: SizedBox(
          height: 56,
          width: 75.0 * _navIcons.length,
          child: Row(
            spacing: 5,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_navIcons.length, (i) {
              final selected = i == _targetPage;
              final primaryColor = Theme.of(context).colorScheme.primary;
              final inactiveColor = Theme.of(context).colorScheme.onSurface.withAlpha(120);

              return Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                child: InkWell(
                  onTap: () => _switchPage(i),
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: selected ? 0 : 8),
                    decoration: BoxDecoration(color: selected ? Theme.of(context).colorScheme.primaryContainer.withAlpha(100) : Colors.transparent, borderRadius: BorderRadius.circular(5)),
                    child: IntrinsicWidth(
                      child: Column(
                        crossAxisAlignment: .center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: .center,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, anim) {
                                  return RotationTransition(
                                    turns: Tween<double>(begin: 0.75, end: 1.0).animate(anim),
                                    child: FadeTransition(
                                      opacity: anim,
                                      child: ScaleTransition(scale: anim, child: child),
                                    ),
                                  );
                                },
                                child: Icon(selected ? _navIcons[i].activeIconData : _navIcons[i].iconData, key: ValueKey<bool>(selected), color: selected ? primaryColor : inactiveColor, size: 20),
                              ),
                              SizedBox(width: 5),
                              Baseline(
                                baseline: 14,
                                baselineType: TextBaseline.alphabetic,
                                child: Text(_navIcons[i].label, style: TextStyle(color: selected ? primaryColor : inactiveColor, fontSize: 14, height: 1.0)),
                              ),
                            ],
                          ),
                          if (selected)
                            Container(
                              margin: EdgeInsets.only(top: 6),
                              height: 2,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [primaryColor.withAlpha(0), primaryColor.withAlpha(120), primaryColor.withAlpha(0)], stops: [0.1, 0.5, 0.9]),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _TitleWidget() {
    return SizedBox(
      width: 279,
      child: Row(
        children: [
          const SizedBox(width: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset("images/icon.jpeg", width: 36, height: 36, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          const Text('Auto Proxy', style: TextStyle(fontSize: 16, height: 1.0)),
          const SizedBox(width: 5),
          Baseline(
            baseline: 11,
            baselineType: TextBaseline.alphabetic,
            child: Text('1.0 Beta', style: TextStyle(fontSize: 11, color: Color(0xFFF5B220))),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData iconData;
  final IconData activeIconData;
  final String label;

  const _NavItem(this.iconData, this.activeIconData, this.label);
}
