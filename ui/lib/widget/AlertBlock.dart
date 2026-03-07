import 'package:flutter/material.dart';

/// 用法：
/// AlertBlock.note(
///   child: Text('普通说明'),
/// ),
/// AlertBlock.warning(
///   child: Column(
///     children: [
///       Text('危险操作！'),
///       ElevatedButton(onPressed: (){}, child: Text('我知道了'))
///     ],
///   ),
/// ),

class AlertBlock extends StatelessWidget {
  final AlertType type;
  final Widget child;

  final IconData? icon;
  final Color? color;
  final String? title;

  const AlertBlock._({required this.type, required this.child, this.icon, this.color, this.title});

  factory AlertBlock.note({required Widget child, IconData? icon, Color? color, String? title}) => AlertBlock._(type: AlertType.note, child: child, icon: icon, color: color, title: title);

  factory AlertBlock.tip({required Widget child, IconData? icon, Color? color, String? title}) => AlertBlock._(type: AlertType.tip, child: child, icon: icon, color: color, title: title);

  factory AlertBlock.important({required Widget child, IconData? icon, Color? color, String? title}) => AlertBlock._(type: AlertType.important, child: child, icon: icon, color: color, title: title);

  factory AlertBlock.warning({required Widget child, IconData? icon, Color? color, String? title}) => AlertBlock._(type: AlertType.warning, child: child, icon: icon, color: color, title: title);

  factory AlertBlock.caution({required Widget child, IconData? icon, Color? color, String? title}) => AlertBlock._(type: AlertType.caution, child: child, icon: icon, color: color, title: title);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final data = _AlertData.fromType(type, scheme);

    final sideColor = color ?? data.side;
    final bgColor = color != null ? color!.withAlpha(30) : data.bg;
    final iconData = icon ?? data.icon;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 0),
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
      color: bgColor,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: sideColor, width: 4)),
          borderRadius: const BorderRadius.all(Radius.circular(5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(iconData, color: sideColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: _Content(title: title, titleColor: sideColor, child: child),
            ),
          ],
        ),
      ),
    );
  }
}

enum AlertType { note, tip, important, warning, caution }

class _AlertData {
  final Color side;
  final Color bg;
  final IconData icon;

  const _AlertData({required this.side, required this.bg, required this.icon});

  factory _AlertData.fromType(AlertType type, ColorScheme scheme) {
    switch (type) {
      case AlertType.note:
        return _AlertData(side: Colors.blue, bg: Colors.blue.withAlpha(50), icon: Icons.info_outline);
      case AlertType.tip:
        return _AlertData(side: Colors.green, bg: Colors.green.withAlpha(50), icon: Icons.lightbulb_outline);
      case AlertType.important:
        return _AlertData(side: Colors.deepPurple, bg: Colors.deepPurple.withAlpha(50), icon: Icons.feedback_outlined);
      case AlertType.warning:
        return _AlertData(side: Colors.orange, bg: Colors.orange.withAlpha(50), icon: Icons.warning_amber);
      case AlertType.caution:
        return _AlertData(side: Colors.red, bg: Colors.red.withAlpha(50), icon: Icons.report_outlined);
    }
  }
}

class _Content extends StatelessWidget {
  final String? title;
  final Widget child;
  final Color titleColor;

  const _Content({this.title, required this.child, required this.titleColor});

  @override
  Widget build(BuildContext context) {
    if (title == null) return child;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title!,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: titleColor),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
