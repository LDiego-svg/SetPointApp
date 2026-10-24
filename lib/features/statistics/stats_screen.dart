import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/sp_widgets.dart';
import '../../models/match_model.dart';

class StatsScreen extends StatefulWidget {
  final MatchModel match;

  const StatsScreen({
    super.key,
    required this.match,
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with AutomaticKeepAliveClientMixin {
  // 0 = ALL, 1 = 1ST, 2 = 2ND, 3 = 3RD, 4 = 4TH, 5 = 5TH
  int _selectedFilterIndex = 0;

  static const List<String> _setChips = [
    'Partido',
    'Set 1',
    'Set 2',
    'Set 3',
    'Set 4',
    'Set 5',
  ];

  MatchModel get _match => widget.match;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final SetStatsData stats = _match.getStatsForFilter(_selectedFilterIndex);

    return ListView(
      primary: true,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: PillTabs(
                    labels: _setChips,
                    selected: _selectedFilterIndex,
                    highlighted: _match.isMatchFinished
                        ? const {}
                        : {_match.currentSet},
                    onChanged: (i) => setState(() => _selectedFilterIndex = i),
                  ),
                ),
                const SizedBox(height: 12),
                _buildMomentumCard(stats),
                const SizedBox(height: 12),
                _buildComparativeStatsCard(stats),
                const SizedBox(height: 12),
                _buildStreaksCard(stats),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color get _homeColor => Color(_match.localTeam.colorValue);
  Color get _awayColor => Color(_match.visitTeam.colorValue);

  // 1. MOMENTUM PUNTO A PUNTO
  Widget _buildMomentumCard(SetStatsData stats) {
    final sp = context.sp;
    final nodes = stats.timeline;
    return SectionCard(
      title: 'Momentum',
      trailing: Text(
        '${nodes.length} puntos',
        style: context.type.labelMedium,
      ),
      child: nodes.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Este set aún no tiene puntos registrados.',
                textAlign: TextAlign.center,
                style: context.type.bodyMedium?.copyWith(color: sp.muted),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _legend(_match.localTeam, _homeColor),
                const SizedBox(height: 6),
                SizedBox(
                  height: 132,
                  child: CustomPaint(
                    painter: _MomentumPainter(
                      nodes: nodes,
                      home: _homeColor,
                      away: _awayColor,
                      axis: sp.line,
                      label: sp.faint,
                      showSetMarks: _selectedFilterIndex == 0,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _legend(_match.visitTeam, _awayColor),
              ],
            ),
    );
  }

  Widget _legend(TeamInfo team, Color color) {
    return Row(
      children: [
        TeamCrest(shortName: team.shortName, color: color, size: 16),
        const SizedBox(width: 6),
        Text(team.name, style: context.type.labelMedium),
      ],
    );
  }

  // 2. COMPARATIVA ESTILO SOFASCORE
  Widget _buildComparativeStatsCard(SetStatsData stats) {
    final rows = <(String, int, int)>[
      ('Puntos totales', stats.localTotalPoints, stats.visitTotalPoints),
      ('Puntos de ataque', stats.localAttacks, stats.visitAttacks),
      ('Puntos de bloqueo', stats.localBlocks, stats.visitBlocks),
      ('Aces', stats.localAces, stats.visitAces),
      ('Errores no forzados', stats.localUnforcedErrors,
          stats.visitUnforcedErrors),
    ];
    return SectionCard(
      title: 'Estadísticas',
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 18),
            _buildSofascoreStatRow(
              title: rows[i].$1,
              localValue: rows[i].$2,
              visitValue: rows[i].$3,
              lowerIsBetter: i == rows.length - 1,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSofascoreStatRow({
    required String title,
    required int localValue,
    required int visitValue,
    bool lowerIsBetter = false,
  }) {
    final sp = context.sp;
    final int total = localValue + visitValue;
    final double localRatio = total == 0 ? 0 : localValue / total;
    final double visitRatio = total == 0 ? 0 : visitValue / total;

    final bool localLeads =
        lowerIsBetter ? localValue < visitValue : localValue > visitValue;
    final bool visitLeads =
        lowerIsBetter ? visitValue < localValue : visitValue > localValue;

    Widget value(int v, bool leads, Color color) => Container(
          constraints: const BoxConstraints(minWidth: 32),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: leads ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$v',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: leads
                  ? (ThemeData.estimateBrightnessForColor(color) ==
                          Brightness.dark
                      ? Colors.white
                      : const Color(0xFF15161A))
                  : sp.ink,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              fontFeatures: kTabular,
            ),
          ),
        );

    Widget bar(double ratio, Color color, bool leads, {required bool rtl}) {
      return Expanded(
        child: Container(
          height: 6,
          decoration: BoxDecoration(
            color: sp.raised,
            borderRadius: BorderRadius.circular(3),
          ),
          alignment: rtl ? Alignment.centerRight : Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: ratio.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: leads ? color : color.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            value(localValue, localLeads, _homeColor),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: sp.ink,
                  fontWeight: FontWeight.w500,
                  fontSize: 13.5,
                ),
              ),
            ),
            value(visitValue, visitLeads, _awayColor),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            bar(localRatio, _homeColor, localLeads, rtl: true),
            const SizedBox(width: 6),
            bar(visitRatio, _awayColor, visitLeads, rtl: false),
          ],
        ),
      ],
    );
  }

  // 3. RACHAS
  Widget _buildStreaksCard(SetStatsData stats) {
    final sp = context.sp;
    final nodes = stats.timeline;
    if (nodes.isEmpty) return const SizedBox.shrink();
    final streaks = _computeStreaks(nodes);

    Widget best(TeamInfo team, int value, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sp.raised,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                TeamCrest(shortName: team.shortName, color: color, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$value seguidos',
                        style: TextStyle(
                          color: sp.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          fontFeatures: kTabular,
                        ),
                      ),
                      Text(
                        'Mejor racha',
                        style: context.type.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    return SectionCard(
      title: 'Rachas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              best(_match.localTeam, streaks.maxLocalStreak, _homeColor),
              const SizedBox(width: 10),
              best(_match.visitTeam, streaks.maxVisitStreak, _awayColor),
            ],
          ),
          if (streaks.streakRuns.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final run in streaks.streakRuns.take(5)) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: run.isLocal ? _homeColor : _awayColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${run.length} puntos de '
                        '${run.isLocal ? _match.localTeamName : _match.visitTeamName}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'Set ${run.setNumber}, hasta ${run.endScore}',
                      style: context.type.labelMedium
                          ?.copyWith(fontFeatures: kTabular),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  _StreakSummary _computeStreaks(List<RallyPointNode> nodes) {
    int maxLocal = 0;
    int maxVisit = 0;
    int currentRun = 0;
    bool? currentIsLocal;
    int currentSet = 1;
    String lastScore = '0-0';

    final List<_StreakRunItem> runs = [];

    for (final node in nodes) {
      if (currentIsLocal == node.isLocalScoring &&
          currentSet == node.setNumber) {
        currentRun++;
      } else {
        if (currentIsLocal != null && currentRun >= 2) {
          runs.add(
            _StreakRunItem(
              isLocal: currentIsLocal,
              length: currentRun,
              setNumber: currentSet,
              endScore: lastScore,
            ),
          );
        }
        currentIsLocal = node.isLocalScoring;
        currentRun = 1;
        currentSet = node.setNumber;
      }

      lastScore = '${node.localScore}-${node.visitScore}';
      if (node.isLocalScoring && currentRun > maxLocal) {
        maxLocal = currentRun;
      } else if (!node.isLocalScoring && currentRun > maxVisit) {
        maxVisit = currentRun;
      }
    }

    if (currentIsLocal != null && currentRun >= 2) {
      runs.add(
        _StreakRunItem(
          isLocal: currentIsLocal,
          length: currentRun,
          setNumber: currentSet,
          endScore: lastScore,
        ),
      );
    }

    // Las más largas primero.
    runs.sort((a, b) => b.length.compareTo(a.length));

    return _StreakSummary(
      maxLocalStreak: maxLocal,
      maxVisitStreak: maxVisit,
      streakRuns: runs,
    );
  }
}

/// Barras de momentum: cada punto aporta +1 (local) o -1 (visitante) y se
/// promedia con una ventana móvil, como el "attack momentum" de Sofascore.
class _MomentumPainter extends CustomPainter {
  final List<RallyPointNode> nodes;
  final Color home;
  final Color away;
  final Color axis;
  final Color label;
  final bool showSetMarks;

  _MomentumPainter({
    required this.nodes,
    required this.home,
    required this.away,
    required this.axis,
    required this.label,
    required this.showSetMarks,
  });

  static const int _window = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final n = nodes.length;
    if (n == 0) return;
    final mid = size.height / 2;
    final slot = size.width / n;
    final gap = slot > 4 ? math.min(2.0, slot * 0.25) : 0.0;
    final maxH = mid - 2;

    // Eje central.
    canvas.drawLine(
      Offset(0, mid),
      Offset(size.width, mid),
      Paint()
        ..color = axis
        ..strokeWidth = 1,
    );

    final values = <double>[];
    for (var i = 0; i < n; i++) {
      var sum = 0.0;
      var count = 0;
      for (var j = i; j >= 0 && j > i - _window; j--) {
        if (nodes[j].setNumber != nodes[i].setNumber) break;
        sum += nodes[j].isLocalScoring ? 1 : -1;
        count++;
      }
      values.add(sum / count);
    }

    final paintHome = Paint()..color = home;
    final paintAway = Paint()..color = away;
    for (var i = 0; i < n; i++) {
      final v = values[i];
      final h = math.max(2.0, v.abs() * maxH);
      final left = i * slot + gap / 2;
      final rect = v >= 0
          ? Rect.fromLTWH(left, mid - h, slot - gap, h)
          : Rect.fromLTWH(left, mid, slot - gap, h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(math.min(2, slot / 3))),
        v >= 0 ? paintHome : paintAway,
      );
    }

    if (showSetMarks) {
      final dash = Paint()
        ..color = axis
        ..strokeWidth = 1;
      for (var i = 1; i < n; i++) {
        if (nodes[i].setNumber == nodes[i - 1].setNumber) continue;
        final x = i * slot;
        for (var y = 0.0; y < size.height; y += 6) {
          canvas.drawLine(Offset(x, y), Offset(x, y + 3), dash);
        }
        final tp = TextPainter(
          text: TextSpan(
            text: 'S${nodes[i].setNumber}',
            style: TextStyle(
              color: label,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x + 3, 0));
      }
    }
  }

  @override
  bool shouldRepaint(_MomentumPainter old) =>
      old.nodes != nodes ||
      old.nodes.length != nodes.length ||
      old.home != home ||
      old.away != away ||
      old.axis != axis ||
      old.showSetMarks != showSetMarks;
}

class _StreakRunItem {
  final bool isLocal;
  final int length;
  final int setNumber;
  final String endScore;

  const _StreakRunItem({
    required this.isLocal,
    required this.length,
    required this.setNumber,
    required this.endScore,
  });
}

class _StreakSummary {
  final int maxLocalStreak;
  final int maxVisitStreak;
  final List<_StreakRunItem> streakRuns;

  const _StreakSummary({
    required this.maxLocalStreak,
    required this.maxVisitStreak,
    required this.streakRuns,
  });
}