import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/sp_widgets.dart';

class GlassNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  const GlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  static const double _height = 64;
  static const double _inset = 6;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Stack(
      children: [
        const Positioned.fill(child: _ScrollEdgeBlur()),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, bottomInset + 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SizedBox(
                height: _height,
                child: Padding(
                  padding: const EdgeInsets.all(_inset),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth =
                          constraints.maxWidth / destinations.length;
                      return Stack(
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(end: selectedIndex.toDouble()),
                            duration: reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 420),
                            curve: Curves.easeOutCubic,
                            builder: (context, pos, child) {
                              final d = (pos - selectedIndex).abs().clamp(
                                0.0,
                                1.0,
                              );
                              final stretch = math.sin(d * math.pi);
                              return Positioned(
                                left: itemWidth * pos,
                                top: 0,
                                bottom: 0,
                                width: itemWidth,
                                child: Transform.scale(
                                  scaleX: 1 + 0.16 * stretch,
                                  scaleY: 1 - 0.07 * stretch,
                                  child: child,
                                ),
                              );
                            },
                            child: const GlassLens(
                              borderRadius: BorderRadius.all(
                                Radius.circular((_height - _inset * 2) / 2),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              for (var i = 0; i < destinations.length; i++)
                                Expanded(
                                  child: _NavItem(
                                    destination: destinations[i],
                                    selected: i == selectedIndex,
                                    onTap: () => onDestinationSelected(i),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScrollEdgeBlur extends StatelessWidget {
  const _ScrollEdgeBlur();

  static const _bands = [(0.0, 1.0), (0.25, 1.0), (0.5, 1.0), (0.75, 1.0)];

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    return IgnorePointer(
      child: Stack(
        children: [
          for (final (start, sigma) in _bands)
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: 1 - start,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    sp.canvas.withValues(alpha: 0),
                    sp.canvas.withValues(alpha: 0.75),
                  ],
                  stops: const [0, 0.7],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final NavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = NavigationBarTheme.of(context);
    final states = {if (selected) WidgetState.selected};
    final iconTheme = theme.iconTheme?.resolve(states);
    final labelStyle = theme.labelTextStyle?.resolve(states);
    return Semantics(
      button: true,
      selected: selected,
      child: Pressable(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme.merge(
              data: iconTheme ?? const IconThemeData(),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: KeyedSubtree(
                  key: ValueKey(selected),
                  child: selected
                      ? destination.selectedIcon ?? destination.icon
                      : destination.icon,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(destination.label, style: labelStyle, maxLines: 1),
          ],
        ),
      ),
    );
  }
}
