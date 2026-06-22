import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import 'glassmorphic_card.dart';

/// A premium, glassmorphic dialog template for the Reimix app.
class ReimixDialog extends StatelessWidget {
  final String title;
  final FaIconData? icon;
  final Widget? body;
  final List<Widget>? actions;
  final Color? accentColor;

  const ReimixDialog({
    super.key,
    required this.title,
    this.icon,
    this.body,
    this.actions,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColorsDark.onBackground : AppColorsLight.onBackground;
    final activeAccent = accentColor ?? Theme.of(context).colorScheme.primary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: GlassmorphicCard(
        borderRadius: 24,
        padding: const EdgeInsets.all(AppDimensions.sp20),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: activeAccent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: FaIcon(
                          icon,
                          color: activeAccent,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.sp12),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.titleLarge(color: textColor).copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              if (body != null) ...[
                const SizedBox(height: AppDimensions.sp16),
                body!,
              ],
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.sp20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A premium, custom-styled list item for lists of options inside [ReimixDialog].
class ReimixDialogMenuItem extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;
  final Widget? trailing;

  const ReimixDialogMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.textColor,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTextColor = isDark ? AppColorsDark.onBackground : AppColorsLight.onBackground;
    final activeTextColor = textColor ?? defaultTextColor;
    final activeIconColor = iconColor ?? (isDark ? AppColorsDark.accent : AppColorsLight.accent);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          splashColor: activeIconColor.withOpacity(0.1),
          highlightColor: activeIconColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                FaIcon(
                  icon,
                  color: activeIconColor,
                  size: 14,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.titleMedium(color: activeTextColor).copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
