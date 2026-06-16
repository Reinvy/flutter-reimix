import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import 'glassmorphic_card.dart';

class FloatingBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const FloatingBottomNavBar({super.key, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.tertiary;
    final unselectedColor = isDark
        ? const Color(0xFFC49EAA)
        : const Color(0xFFA07080); // match subtext

    final items = [
      (
        inactiveIcon: FontAwesomeIcons.house,
        activeIcon: FontAwesomeIcons.solidHouse,
        label: 'Home',
      ),
      (inactiveIcon: FontAwesomeIcons.music, activeIcon: FontAwesomeIcons.music, label: 'Library'),
      (inactiveIcon: FontAwesomeIcons.list, activeIcon: FontAwesomeIcons.list, label: 'Playlists'),
      (
        inactiveIcon: FontAwesomeIcons.magnifyingGlass,
        activeIcon: FontAwesomeIcons.magnifyingGlass,
        label: 'Search',
      ),
    ];

    return Container(
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH, vertical: 16),
      child: GlassmorphicCard(
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final double itemWidth = width / items.length;

            return Stack(
              children: [
                // Sliding Active Indicator Capsule
                AnimatedAlign(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment(-1.0 + (selectedIndex * (2.0 / (items.length - 1))), 0.0),
                  child: Container(
                    width: itemWidth - 12,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(50),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accentColor.withAlpha(80), width: 1),
                    ),
                  ),
                ),
                // Tab Buttons
                Row(
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final isSelected = selectedIndex == index;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onTap(index),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              duration: const Duration(milliseconds: 200),
                              scale: isSelected ? 1.15 : 1.0,
                              child: FaIcon(
                                isSelected ? item.activeIcon : item.inactiveIcon,
                                color: isSelected ? accentColor : unselectedColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.label,
                              style:
                                  AppTextStyles.labelSmall(
                                    color: isSelected ? accentColor : unselectedColor,
                                  ).copyWith(
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 10,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
