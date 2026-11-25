import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/live_clock.dart';
import '../../core/widgets/sp_widgets.dart';
import '../../models/match_model.dart';
import 'match_controller.dart';

Object crestHeroTag(String matchId, {required bool isLocal}) =>
    'crest-$matchId-${isLocal ? 'local' : 'visit'}';

class CrestHero extends StatelessWidget {
  final String matchId;
  final bool isLocal;
  final TeamInfo team;
  final double size;
  final bool halo;

  const CrestHero({
    super.key,
    required this.matchId,
    required this.isLocal,
    required this.team,
    required this.size,
    this.halo = false,
  });

  static const double _flightSize = 56;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: crestHeroTag(matchId, isLocal: isLocal),
      flightShuttleBuilder: _shuttle,
      child: _Crest(team: team, size: size, haloStrength: halo ? 1 : 0),
    );
  }

  Widget _shuttle(
    BuildContext context,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromContext,
    BuildContext toContext,
  ) {
    // Material transparente evita el subrayado amarillo de debug durante el Hero.
    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => FittedBox(
          child: _Crest(
            team: team,
            size: _flightSize,
            haloStrength: Curves.easeIn.transform(animation.value),
          ),
        ),
      ),
    );
  }
}

class _Crest extends StatelessWidget {
  final TeamInfo team;
  final double size;
  final double haloStrength;

  const _Crest({
    required this.team,
    required this.size,
    required this.haloStrength,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(team.colorValue);
    final crest = TeamCrest(
      shortName: team.shortName,
      color: color,
      size: size,
    );
    if (haloStrength <= 0) return crest;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4 * haloStrength),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: crest,
    );
  }
}

String? setPointAlert(MatchModel m) {
  if (!m.isLive) return null;
  final target = m.targetPointsForCurrentSet;
  final l = m.localPoints;
  final v = m.visitPoints;
  if (l >= target - 1 && l - v >= 1) {
    return m.localSetsWon == m.setsToWin - 1
        ? 'Punto de partido para ${m.localTeamName}'
        : 'Punto de set para ${m.localTeamName}';
  }
  if (v >= target - 1 && v - l >= 1) {
    return m.visitSetsWon == m.setsToWin - 1
        ? 'Punto de partido para ${m.visitTeamName}'
        : 'Punto de set para ${m.visitTeamName}';
  }
  return null;
}

class ScoreHeader extends StatelessWidget {
  final MatchModel match;
  final MatchController controller;
  const ScoreHeader({super.key, required this.match, required this.controller});

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final m = match;
    final alert = setPointAlert(m);
    final finishedSets = m.setsHistory.where((s) => s.isCompleted).toList();
    final wash = Theme.of(context).brightness == Brightness.dark ? 0.22 : 0.14;

    RadialGradient glow(int colorValue, double x) => RadialGradient(
      center: Alignment(x, -0.1),
      radius: 1.1,
      colors: [
        Color(colorValue).withValues(alpha: wash),
        Color(colorValue).withValues(alpha: 0),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(color: sp.card),
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: glow(m.localTeam.colorValue, -0.7)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: glow(m.visitTeam.colorValue, 0.7),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  sp.card,
                  sp.card.withValues(alpha: 0),
                  sp.card.withValues(alpha: 0),
                  sp.card,
                ],
                stops: const [0, 0.3, 0.6, 1],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _TeamColumn(match: m, isLocal: true)),
                          SizedBox(
                            width: 170,
                            child: _CenterScore(
                              match: m,
                              controller: controller,
                            ),
                          ),
                          Expanded(
                            child: _TeamColumn(match: m, isLocal: false),
                          ),
                        ],
                      ),
                      if (finishedSets.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 14,
                          runSpacing: 4,
                          children: [
                            for (final s in finishedSets)
                              Text(
                                '${s.localScore}-${s.visitScore} '
                                '(${formatDurationSeconds(s.durationSeconds)})',
                                style: context.type.labelMedium?.copyWith(
                                  fontFeatures: kTabular,
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (m.recentEvent.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          m.recentEvent,
                          textAlign: TextAlign.center,
                          style: context.type.bodySmall?.copyWith(
                            color: sp.muted,
                          ),
                        ),
                      ],
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: alert == null
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: _SetPointBadge(text: alert),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterScore extends StatelessWidget {
  final MatchModel match;
  final MatchController controller;
  const _CenterScore({required this.match, required this.controller});

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final m = match;
    final big = context.type.displaySmall!.copyWith(
      fontSize: 44,
      color: m.isUpcoming ? sp.faint : sp.ink,
    );
    final status = TextStyle(fontWeight: FontWeight.w700, fontSize: 13);

    final local = m.isLive ? m.localPoints : m.localSetsWon;
    final visit = m.isLive ? m.visitPoints : m.visitSetsWon;

    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AnimatedNumber(value: local, style: big),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  m.isLive ? ':' : '–',
                  style: big.copyWith(color: sp.faint),
                ),
              ),
              _AnimatedNumber(value: visit, style: big),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (m.isUpcoming) ...[
                Text('Por empezar', style: status.copyWith(color: sp.brand)),
                const SizedBox(width: 8),
                Text(
                  '00:00',
                  style: status.copyWith(
                    color: sp.faint,
                    fontFeatures: kTabular,
                  ),
                ),
              ] else if (m.isLive) ...[
                const LiveDot(),
                const SizedBox(width: 6),
                Text(
                  '${m.currentSet}.º set',
                  style: status.copyWith(color: sp.live),
                ),
                const SizedBox(width: 8),
                Pressable(
                  onTap: controller.toggleTimer,
                  child: LiveClock(
                    enabled: m.isTimerRunning,
                    builder: (_) => Text(
                      formatDurationSeconds(m.currentSetElapsedSeconds),
                      style: status.copyWith(
                        color: m.isTimerRunning ? sp.live : sp.muted,
                        fontFeatures: kTabular,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Text('Finalizado', style: status.copyWith(color: sp.muted)),
                const SizedBox(width: 8),
                Text(
                  formatDurationSeconds(m.totalMatchElapsedSeconds),
                  style: status.copyWith(
                    color: sp.muted,
                    fontFeatures: kTabular,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (m.isLive) ...[
          const SizedBox(height: 8),
          _SetsPill(local: m.localSetsWon, visit: m.visitSetsWon),
        ],
      ],
    );
  }
}

class _SetsPill extends StatelessWidget {
  final int local;
  final int visit;
  const _SetsPill({required this.local, required this.visit});

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final style = TextStyle(
      color: sp.ink,
      fontSize: 13,
      fontWeight: FontWeight.w800,
      fontFeatures: kTabular,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: sp.raised,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Sets ', style: style.copyWith(color: sp.muted)),
          _AnimatedNumber(value: local, style: style),
          Text(' – ', style: style.copyWith(color: sp.faint)),
          _AnimatedNumber(value: visit, style: style),
        ],
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  final MatchModel match;
  final bool isLocal;
  const _TeamColumn({required this.match, required this.isLocal});

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final team = isLocal ? match.localTeam : match.visitTeam;
    final serving = match.isLive && match.isLocalServing == isLocal;
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CrestHero(
              matchId: match.id,
              isLocal: isLocal,
              team: team,
              size: 56,
              halo: true,
            ),
            if (serving)
              Positioned(
                right: -4,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: sp.card,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.sports_volleyball,
                    size: 14,
                    color: sp.brand,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          team.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.type.titleSmall,
        ),
      ],
    );
  }
}

class _SetPointBadge extends StatefulWidget {
  final String text;
  const _SetPointBadge({required this.text});

  @override
  State<_SetPointBadge> createState() => _SetPointBadgeState();
}

class _SetPointBadgeState extends State<_SetPointBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse
        ..stop()
        ..value = 0.5;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.bolt_rounded, size: 16, color: sp.onAccent),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            widget.text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: sp.onAccent,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: sp.accent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: sp.accent.withValues(alpha: 0.25 + 0.3 * t),
                blurRadius: 6 + 10 * t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: content,
    );
  }
}

class _AnimatedNumber extends StatelessWidget {
  final int value;
  final TextStyle style;
  const _AnimatedNumber({required this.value, required this.style});

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: Duration(milliseconds: reduce ? 0 : 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) {
        final incoming = child.key == ValueKey(value);
        final offset = Tween<Offset>(
          begin: Offset(0, incoming ? 0.5 : -0.5),
          end: Offset.zero,
        ).animate(anim);
        return ClipRect(
          child: SlideTransition(
            position: offset,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.7, end: 1).animate(anim),
              child: FadeTransition(opacity: anim, child: child),
            ),
          ),
        );
      },
      child: Text('$value', key: ValueKey(value), style: style),
    );
  }
}
