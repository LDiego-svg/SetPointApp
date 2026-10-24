import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/sp_widgets.dart';
import '../../data/match_repository.dart';
import '../../models/match_model.dart';
import '../lineup/lineup_screen.dart';
import '../scoreboard/scoreboard_screen.dart';
import '../statistics/stats_screen.dart';
import 'match_controller.dart';

class MatchDetailScreen extends StatefulWidget {
  final String matchId;
  final MatchModel? initial;

  const MatchDetailScreen({super.key, required this.matchId, this.initial});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  MatchController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= MatchController(
      repository: RepositoryScope.of(context),
      matchId: widget.matchId,
      initial: widget.initial,
    )..addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    final c = _controller!;
    final msg = c.saveError;
    if (msg != null && mounted) {
      c.clearSaveError();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _openEditSheet(MatchModel m) async {
    final localCtrl = TextEditingController(text: m.localTeamName);
    final visitCtrl = TextEditingController(text: m.visitTeamName);
    final tournamentCtrl = TextEditingController(text: m.tournament.name);
    final stageCtrl = TextEditingController(text: m.stage);
    final venueCtrl = TextEditingController(text: m.venue);
    final recentCtrl = TextEditingController(text: m.recentEvent);
    final setCtrl = TextEditingController(text: '${m.currentSet}');
    final localSetsCtrl = TextEditingController(text: '${m.localSetsWon}');
    final visitSetsCtrl = TextEditingController(text: '${m.visitSetsWon}');
    final localPtsCtrl = TextEditingController(text: '${m.localPoints}');
    final visitPtsCtrl = TextEditingController(text: '${m.visitPoints}');
    bool isFinished = m.isMatchFinished;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.sp.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Editar partido en Firestore',
                            style: sheetCtx.type.titleMedium,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: localCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Equipo local (localName)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: visitCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Equipo visitante (visitName)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tournamentCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Torneo (tournament)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: stageCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Fase / Jornada (stage)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: venueCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Sede (venue)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: setCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Set actual',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: localSetsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Sets local',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: visitSetsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Sets visita',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: localPtsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Puntos local',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: visitPtsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Puntos visita',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: recentCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Evento reciente (recentEvent)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Partido finalizado (isFinished)'),
                      value: isFinished,
                      onChanged: (v) => setModalState(() => isFinished = v),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () async {
                        Navigator.pop(sheetCtx);
                        await _controller!.updateMatchDetails(
                          localName: localCtrl.text,
                          visitName: visitCtrl.text,
                          tournamentName: tournamentCtrl.text,
                          stage: stageCtrl.text,
                          venue: venueCtrl.text,
                          currentSet:
                              int.tryParse(setCtrl.text) ?? m.currentSet,
                          localSets:
                              int.tryParse(localSetsCtrl.text) ?? m.localSetsWon,
                          visitSets:
                              int.tryParse(visitSetsCtrl.text) ?? m.visitSetsWon,
                          localPoints:
                              int.tryParse(localPtsCtrl.text) ?? m.localPoints,
                          visitPoints:
                              int.tryParse(visitPtsCtrl.text) ?? m.visitPoints,
                          isFinished: isFinished,
                          recentEvent: recentCtrl.text,
                        );
                      },
                      child: const Text('Guardar cambios en Firestore'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller!;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final m = c.match;
        if (m == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: c.loading
                  ? const CircularProgressIndicator(strokeWidth: 2.4)
                  : Text(
                      c.notFound
                          ? 'Este partido ya no existe en la base de datos.'
                          : 'No se pudo cargar el partido.\n${c.error ?? ''}',
                      textAlign: TextAlign.center,
                    ),
            ),
          );
        }
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              titleSpacing: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.tournament.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  if (m.stage.isNotEmpty)
                    Text(
                      m.stage,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.sp.onHeader.withValues(alpha: 0.75),
                      ),
                    ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Reiniciar partido a 0-0',
                  onPressed: () async {
                    await c.resetMatch();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Partido reiniciado a 0-0 (Día 24 · 8:30 AM)',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.restart_alt_rounded),
                ),
                IconButton(
                  tooltip: 'Editar datos en Firestore',
                  onPressed: () => _openEditSheet(m),
                  icon: const Icon(Icons.edit_note_rounded),
                ),
                const SizedBox(width: 4),
              ],
            ),
            body: NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverToBoxAdapter(child: _ScoreHeader(match: m)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(context.sp.card),
                ),
              ],
              body: TabBarView(
                children: [
                  ScoreboardScreen(controller: c),
                  StatsScreen(match: m),
                  LineupScreen(controller: c),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final Color background;
  _TabBarDelegate(this.background);

  @override
  double get minExtent => 46;
  @override
  double get maxExtent => 46;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(
      color: background,
      child: const TabBar(
        tabs: [
          Tab(text: 'Detalles'),
          Tab(text: 'Estadísticas'),
          Tab(text: 'Alineación'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => old.background != background;
}

/// Texto de alerta de punto de set / partido, o null si no aplica.
String? setPointAlert(MatchModel m) {
  if (m.isMatchFinished) return null;
  final target = m.targetPointsForCurrentSet;
  final l = m.localPoints;
  final v = m.visitPoints;
  if (l >= target - 1 && l - v >= 1) {
    return m.localSetsWon == 2
        ? 'Punto de partido para ${m.localTeamName}'
        : 'Punto de set para ${m.localTeamName}';
  }
  if (v >= target - 1 && v - l >= 1) {
    return m.visitSetsWon == 2
        ? 'Punto de partido para ${m.visitTeamName}'
        : 'Punto de set para ${m.visitTeamName}';
  }
  return null;
}

class _ScoreHeader extends StatelessWidget {
  final MatchModel match;
  const _ScoreHeader({required this.match});

  String _formatSchedule(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour < 12 ? 'AM' : 'PM';
    return 'Día ${t.day} · $h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final m = match;
    final live = !m.isMatchFinished;
    final alert = setPointAlert(m);
    final finishedSets = m.setsHistory.where((s) => s.isCompleted).toList();

    return Container(
      color: sp.card,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  [
                    _formatSchedule(m.startTime),
                    if (m.venue.isNotEmpty) m.venue,
                  ].join(' · '),
                  textAlign: TextAlign.center,
                  style: context.type.labelSmall?.copyWith(color: sp.muted),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _TeamColumn(match: m, isLocal: true)),
                  SizedBox(
                    width: 150,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _AnimatedNumber(
                              value: m.localSetsWon,
                              style: context.type.displaySmall!,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text('–',
                                  style: context.type.displaySmall
                                      ?.copyWith(color: sp.faint)),
                            ),
                            _AnimatedNumber(
                              value: m.visitSetsWon,
                              style: context.type.displaySmall!,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (live) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const LiveDot(),
                              const SizedBox(width: 6),
                              Text(
                                '${m.currentSet}.º set',
                                style: TextStyle(
                                  color: sp.live,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _AnimatedNumber(
                                  value: m.localPoints,
                                  style: _pointsStyle(sp),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6),
                                  child: Text(':', style: _pointsStyle(sp)),
                                ),
                                _AnimatedNumber(
                                  value: m.visitPoints,
                                  style: _pointsStyle(sp),
                                ),
                              ],
                            ),
                          ),
                        ] else
                          Text(
                            'Finalizado',
                            style: TextStyle(
                              color: sp.muted,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(child: _TeamColumn(match: m, isLocal: false)),
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
                        '${s.localScore}-${s.visitScore}',
                        style: context.type.labelMedium
                            ?.copyWith(fontFeatures: kTabular),
                      ),
                  ],
                ),
              ],
              if (m.recentEvent.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  m.recentEvent,
                  textAlign: TextAlign.center,
                  style: context.type.bodySmall?.copyWith(color: sp.muted),
                ),
              ],
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: alert == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: sp.live.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            alert,
                            style: TextStyle(
                              color: sp.live,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _pointsStyle(SpColors sp) => TextStyle(
        color: sp.live,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        fontFeatures: kTabular,
      );
}

class _TeamColumn extends StatelessWidget {
  final MatchModel match;
  final bool isLocal;
  const _TeamColumn({required this.match, required this.isLocal});

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final team = isLocal ? match.localTeam : match.visitTeam;
    final serving =
        !match.isMatchFinished && match.isLocalServing == isLocal;
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            TeamCrest(
              shortName: team.shortName,
              color: Color(team.colorValue),
              size: 52,
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
                  child: Icon(Icons.sports_volleyball,
                      size: 14, color: sp.brand),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
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

/// Número que se desliza hacia arriba al cambiar: comunica qué cambió sin
/// llamar la atención. Sin animación si el sistema pide reducir movimiento.
class _AnimatedNumber extends StatelessWidget {
  final int value;
  final TextStyle style;
  const _AnimatedNumber({required this.value, required this.style});

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return AnimatedSwitcher(
      duration: Duration(milliseconds: reduce ? 0 : 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) {
        final incoming = child.key == ValueKey(value);
        final offset = Tween<Offset>(
          begin: Offset(0, incoming ? 0.45 : -0.45),
          end: Offset.zero,
        ).animate(anim);
        return ClipRect(
          child: SlideTransition(
            position: offset,
            child: FadeTransition(opacity: anim, child: child),
          ),
        );
      },
      child: Text('$value', key: ValueKey(value), style: style),
    );
  }
}
