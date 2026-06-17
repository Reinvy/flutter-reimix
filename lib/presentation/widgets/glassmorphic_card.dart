import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// A frosted-glass card using backdrop blur and a semi-transparent pink tint.
///
/// Wrap any [child] content to give it a glassmorphic appearance consistent
/// with the cherry-blossom design system.
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = AppDimensions.radiusCard,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayColor = isDark
        ? AppColorsDark.primary.withAlpha(180)
        : AppColorsLight.primary.withAlpha(200);
    final borderColor = isDark
        ? AppColorsLight.divider.withAlpha(40)
        : AppColorsLight.divider.withAlpha(128);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppDimensions.blurGlassCard,
          sigmaY: AppDimensions.blurGlassCard,
        ),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: overlayColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
