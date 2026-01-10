import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A floating navigation bar with rounded top corners and elevation
class FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<FloatingNavDestination> destinations;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? backgroundColor;
  final double? badgeCount;

  const FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.activeColor,
    this.inactiveColor,
    this.backgroundColor,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use Material 3 colors from theme
    final active = activeColor ?? colorScheme.primary;
    final inactive = inactiveColor ?? colorScheme.onSurfaceVariant;
    final background = backgroundColor ?? colorScheme.surfaceContainerHighest;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(destinations.length, (index) {
            final destination = destinations[index];
            final isSelected = index == selectedIndex;
            final color = isSelected ? active : inactive;

            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onDestinationSelected(index);
                  },
                  borderRadius: BorderRadius.circular(12),
                  // Ensure minimum touch target of 44x44
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 44,
                      minWidth: 44,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  isSelected
                                      ? destination.selectedIcon
                                      : destination.icon,
                                  key: ValueKey(
                                    '${destination.icon.codePoint}_$isSelected',
                                  ),
                                  color: color,
                                  size: 24,
                                ),
                              ),
                              if (destination.badgeCount != null &&
                                  destination.badgeCount! > 0)
                                Positioned(
                                  right: -8,
                                  top: -8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.error,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      destination.badgeCount! > 99
                                          ? '99+'
                                          : '${destination.badgeCount}',
                                      style: TextStyle(
                                        color: theme.colorScheme.onError,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (destination.label != null) ...[
                            const SizedBox(height: 4),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              child: Text(destination.label!),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Configuration for a navigation destination
class FloatingNavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String? label;
  final int? badgeCount;

  const FloatingNavDestination({
    required this.icon,
    required this.selectedIcon,
    this.label,
    this.badgeCount,
  });
}
