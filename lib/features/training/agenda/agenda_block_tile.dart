import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/sp_widgets.dart';
import 'schedule_models.dart';

class AgendaBlockTile extends StatelessWidget {
  final ScheduleBlock block;
  final bool isNow;
  final bool isNext;
  final double progress;
  final bool isLast;
  final VoidCallback onTap;

  const AgendaBlockTile({
    super.key,
    required this.block,
    required this.isNow,
    required this.isNext,
    required this.progress,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final color = block.type.color;
    final timeStyle = TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      fontFeatures: kTabular,
      color: isNow ? color : sp.ink,
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 46,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(formatMinutes(block.start), style: timeStyle),
                  Text(
                    formatMinutes(block.end),
                    style: timeStyle.copyWith(
                      color: sp.faint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 18,
            child: Column(
              children: [
                const SizedBox(height: 14),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isNow ? color : sp.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: sp.line,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Pressable(
                onTap: onTap,
                pressedScale: 0.98,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isNow ? 0.16 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isNow
                          ? color.withValues(alpha: 0.6)
                          : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(block.type.icon, size: 18, color: color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              block.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.type.titleSmall,
                            ),
                          ),
                          if (isNow)
                            _Badge(text: 'Ahora', color: color, solid: true)
                          else if (isNext)
                            _Badge(text: 'Siguiente', color: color),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          block.type.label,
                          if (block.place.isNotEmpty) block.place,
                          _duration(block.durationMinutes),
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.type.bodySmall,
                      ),
                      if (isNow) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: color.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _duration(int m) =>
      m < 60 ? '$m min' : '${m ~/ 60} h${m % 60 > 0 ? ' ${m % 60} min' : ''}';
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final bool solid;
  const _Badge({required this.text, required this.color, this.solid = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: solid ? color : color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: solid ? Colors.white : color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
