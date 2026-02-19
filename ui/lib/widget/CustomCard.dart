import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget? title;
  final Widget child;
  final IconData? icon;
  final Color? color;
  final double elevation;
  final double borderRadius;
  final double titleSpacing;
  final Color? shadowColor;
  final double shadowIntensity;
  final double shadowSpread;
  final double shadowBlur;
  final Offset shadowOffset;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;

  const CustomCard({
    super.key,
    this.title,
    required this.child,
    this.icon,
    this.color,
    this.elevation = 0,
    this.borderRadius = 5,
    this.titleSpacing = 3,
    this.shadowColor,
    this.shadowIntensity = 0.4,
    this.shadowSpread = 1,
    this.shadowBlur = 5,
    this.shadowOffset = const Offset(0, 4),
    this.margin = const EdgeInsets.all(4.0),
    this.padding = const EdgeInsets.all(10),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final effectiveShadowColor =
        shadowColor ?? (theme.brightness == Brightness.dark ? Colors.black : Colors.grey.shade400);

    final alpha = (shadowIntensity * 255).clamp(0, 255).toInt();

    return Card(
      margin: margin,
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      child: Container(
        decoration: BoxDecoration(
          color: color ?? theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: elevation > 0
              ? [
                  BoxShadow(
                    color: effectiveShadowColor.withAlpha(alpha),
                    spreadRadius: shadowSpread,
                    blurRadius: shadowBlur * (elevation / 10).clamp(0.5, 3),
                    offset: Offset(shadowOffset.dx * (elevation / 5), shadowOffset.dy * (elevation / 5)),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null)
                if (icon != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(icon, color: theme.colorScheme.primary),
                      SizedBox(width: titleSpacing),
                      title!,
                    ],
                  )
                else
                  title!,
              if (title != null) const Divider(thickness: 1),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
