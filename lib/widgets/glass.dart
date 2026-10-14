import 'package:flutter/material.dart';

import '../core/theme.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final bool glow;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.radius = AppRadius.lg,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: AppColors.glassGradient,
        color: AppColors.glass,
        border: Border.all(color: AppColors.glassBorder, width: 1),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.10),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ]
            : const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
      ),
      padding: padding,
      child: Material(color: Colors.transparent, child: child),
    );
    return w;
  }
}

class NeonButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool secondary;
  final bool compact;
  final Color? solid;
  final Color borderColor;
  final bool outline;
  final bool highlight;

  const NeonButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.secondary = false,
    this.compact = false,
    this.solid,
    this.borderColor = AppColors.accent,
    this.outline = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outline) {
      final enabled = onTap != null;
      final tint = enabled ? borderColor : AppColors.textTertiary;
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          color: highlight ? tint.withValues(alpha: 0.14) : Colors.transparent,
          border: Border.all(
            color: highlight ? tint : tint.withValues(alpha: 0.55),
            width: highlight ? 1.6 : 1.2,
          ),
          boxShadow: highlight
              ? [
                  BoxShadow(
                    color: tint.withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 3),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? AppSpacing.md + 2 : AppSpacing.lg,
                vertical: AppSpacing.sm + 4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 17, color: highlight ? tint : AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.sm - 2),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: highlight ? tint : AppColors.textPrimary,
                        fontWeight:
                            highlight ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 13.5,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (secondary) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: onTap == null
                ? Colors.white12
                : AppColors.glassBorder,
          ),
        ),
      );
    }
    final enabled = onTap != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        gradient: (enabled && solid == null) ? AppColors.accentGradient : null,
        color: solid != null
            ? (enabled ? solid : solid!.withValues(alpha: 0.35))
            : (enabled ? null : AppColors.cardDeep2),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: (solid ?? AppColors.accent).withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? AppSpacing.md : AppSpacing.xl,
              vertical: AppSpacing.md + 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 18,
                    color: enabled
                        ? Colors.white
                        : AppColors.textTertiary),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: enabled
                          ? Colors.white
                          : AppColors.textTertiary,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 13.5 : 15,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const StatChip({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      radius: AppRadius.sm,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.16),
              border: Border.all(color: color.withValues(alpha: 0.45)),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color,
                      fontFamilyFallback: const ['Consolas', 'monospace'],
                    ),
                  ),
                  Text(
                    label,textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? hint;
  final Widget? trailing;

  const SectionTitle({super.key, required this.title, this.hint, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: AppColors.accentGradient,
          ),
        ),
        const SizedBox(width: AppSpacing.sm + 2),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              hint!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ] else
          const Spacer(),
        ?trailing,
      ],
    );
  }
}

TextStyle monoStyle({double size = 13.5, Color? color, FontWeight w = FontWeight.w600}) =>
    TextStyle(
      fontSize: size,
      color: color ?? AppColors.textPrimary,
      fontWeight: w,
      fontFamilyFallback: const ['Consolas', 'Menlo', 'monospace'],
      letterSpacing: 0.2,
    );
