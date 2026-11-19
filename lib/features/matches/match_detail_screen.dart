import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../data/match_repository.dart';
import '../../models/match_model.dart';
import '../lineup/lineup_screen.dart';
import '../scoreboard/scoreboard_screen.dart';
import '../statistics/stats_screen.dart';
import 'match_controller.dart';
import 'score_header.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(glassSnackBar(msg));
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
    MatchStatus selectedStatus = m.status;

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
                    const SizedBox(height: 12),
                    Text(
                      'Estado del partido (status)',
                      style: sheetCtx.type.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<MatchStatus>(
                      segments: const [
                        ButtonSegment(
                          value: MatchStatus.upcoming,
                          label: Text('Por empezar'),
                          icon: Icon(Icons.schedule_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: MatchStatus.live,
                          label: Text('En vivo'),
                          icon: Icon(
                            Icons.play_circle_outline_rounded,
                            size: 16,
                          ),
                        ),
                        ButtonSegment(
                          value: MatchStatus.finished,
                          label: Text('Finalizado'),
                          icon: Icon(Icons.flag_rounded, size: 16),
                        ),
                      ],
                      selected: {selectedStatus},
                      onSelectionChanged: (s) =>
                          setModalState(() => selectedStatus = s.first),
                    ),
                    const SizedBox(height: 16),
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
                              int.tryParse(localSetsCtrl.text) ??
                              m.localSetsWon,
                          visitSets:
                              int.tryParse(visitSetsCtrl.text) ??
                              m.visitSetsWon,
                          localPoints:
                              int.tryParse(localPtsCtrl.text) ?? m.localPoints,
                          visitPoints:
                              int.tryParse(visitPtsCtrl.text) ?? m.visitPoints,
                          status: selectedStatus,
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
              leading: Center(
                child: GlassIconButton(
                  tooltip: 'Atrás',
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              titleSpacing: 4,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.tournament.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
                GlassIconButton(
                  tooltip: 'Reiniciar partido a 0-0',
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('¿Reiniciar partido?'),
                        content: const Text(
                          'El marcador, los sets, las estadísticas y los '
                          'eventos de este partido volverán a 0. Esta acción '
                          'no se puede deshacer.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Reiniciar'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    final ok = await c.resetMatch();
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        glassSnackBar(
                          'Partido reiniciado a 0-0',
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: Icons.restart_alt_rounded,
                ),
                const SizedBox(width: 8),
                GlassIconButton(
                  tooltip: 'Editar datos en Firestore',
                  onPressed: () => _openEditSheet(m),
                  icon: Icons.edit_note_rounded,
                ),
                const SizedBox(width: 14),
              ],
            ),
            body: NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverToBoxAdapter(
                  child: ScoreHeader(match: m, controller: c),
                ),
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
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(
      color: background,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: const GlassTabBar(
        labels: ['Detalles', 'Estadísticas', 'Alineación'],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => old.background != background;
}
