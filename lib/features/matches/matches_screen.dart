import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/sp_widgets.dart';
import '../../data/match_repository.dart';
import '../../models/match_model.dart';
import 'match_detail_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  // 0 = todos, 1 = por empezar, 2 = en vivo, 3 = finalizados
  int _filter = 0;
  bool _seeding = false;
  Stream<List<MatchModel>>? _stream;
  MatchRepository? _repo;
  Timer? _clockTicker;

  @override
  void initState() {
    super.initState();
    _clockTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTicker?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = RepositoryScope.of(context);
    if (repo != _repo) {
      _repo = repo;
      _stream = repo.watchMatches();
    }
  }

  Future<void> _seed() async {
    setState(() => _seeding = true);
    try {
      await _repo!.seedSampleData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Partido reiniciado en Firestore (0-0 · Día 24, 8:30 AM)',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar el partido: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  void _open(MatchModel match) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RepositoryScope(
          repository: _repo!,
          child: MatchDetailScreen(matchId: match.id, initial: match),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Row(
          children: [
            Icon(Icons.sports_volleyball, size: 22),
            SizedBox(width: 10),
            Text('SetPoint'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Restaurar partido de ejemplo en Firestore',
            onPressed: _seeding ? null : _seed,
            icon: _seeding
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: sp.onHeader,
                    ),
                  )
                : const Icon(Icons.restart_alt_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: StreamBuilder<List<MatchModel>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return _Message(
              icon: Icons.cloud_off_rounded,
              title: 'No se pudo leer la base de datos',
              body: 'Revisa tu conexión y que las reglas de Firestore '
                  'permitan leer las colecciones matches, teams y tournaments.\n\n'
                  '${snap.error}',
            );
          }
          if (!snap.hasData) {
            return Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: sp.brand,
                ),
              ),
            );
          }

          final all = snap.data!;
          if (all.isEmpty) {
            return _Message(
              icon: Icons.sports_volleyball_outlined,
              title: 'Aún no hay partidos',
              body: 'Crea el partido de ejemplo para empezar. Después podrás '
                  'editar equipos, torneo y marcador desde la consola de '
                  'Firebase o desde la app.',
              action: FilledButton(
                onPressed: _seeding ? null : _seed,
                child: Text(
                  _seeding ? 'Creando…' : 'Crear partido de ejemplo',
                ),
              ),
            );
          }

          final upcoming = all.where((m) => m.isUpcoming).length;
          final live = all.where((m) => m.isLive).length;
          final done = all.where((m) => m.isMatchFinished).length;
          final visible = switch (_filter) {
            1 => all.where((m) => m.isUpcoming).toList(),
            2 => all.where((m) => m.isLive).toList(),
            3 => all.where((m) => m.isMatchFinished).toList(),
            _ => all,
          };

          // Agrupar por torneo conservando el orden.
          final groups = <String, List<MatchModel>>{};
          for (final m in visible) {
            groups.putIfAbsent(m.tournament.id, () => []).add(m);
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: PillTabs(
                      labels: [
                        'Todos ${all.length}',
                        'Por empezar $upcoming',
                        'En vivo $live',
                        'Finalizados $done',
                      ],
                      selected: _filter,
                      highlighted: live > 0 ? {2} : const {},
                      onChanged: (i) => setState(() => _filter = i),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (groups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        switch (_filter) {
                          1 => 'No hay partidos por empezar.',
                          2 => 'No hay partidos en vivo ahora mismo.',
                          _ => 'Todavía no hay partidos finalizados.',
                        },
                        textAlign: TextAlign.center,
                        style: context.type.bodyMedium
                            ?.copyWith(color: sp.muted),
                      ),
                    ),
                  for (final g in groups.values) ...[
                    _TournamentBlock(matches: g, onOpen: _open),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TournamentBlock extends StatelessWidget {
  final List<MatchModel> matches;
  final ValueChanged<MatchModel> onOpen;

  const _TournamentBlock({required this.matches, required this.onOpen});

  static List<SetStatsData> _playedSetsFor(MatchModel m) {
    return m.setsHistory
        .where(
          (s) => s.isCompleted || (!m.isMatchFinished && s.setNumber == m.currentSet),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final t = matches.first.tournament;
    var maxSetColumns = 1;
    for (final m in matches) {
      final count = _playedSetsFor(m).length;
      if (count > maxSetColumns) maxSetColumns = count;
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: sp.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: sp.raised,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.emoji_events_outlined,
                      size: 16, color: sp.muted),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.name, style: context.type.titleSmall),
                      if (t.category.isNotEmpty || t.season.isNotEmpty)
                        Text(
                          [t.category, t.season]
                              .where((s) => s.isNotEmpty)
                              .join(', '),
                          style: context.type.labelSmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final m in matches) ...[
            const Divider(),
            _MatchRow(
              match: m,
              setColumns: maxSetColumns,
              onTap: () => onOpen(m),
            ),
          ],
        ],
      ),
    );
  }
}

String _formatTimeAmPm(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  final period = t.hour < 12 ? 'AM' : 'PM';
  return '$h:$m $period';
}

/// Fila de partido estilo Sofascore:
/// [hora / estado] | [equipos] [sets] [parciales]
class _MatchRow extends StatelessWidget {
  final MatchModel match;
  final int setColumns;
  final VoidCallback onTap;

  const _MatchRow({
    required this.match,
    required this.setColumns,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final m = match;
    final playedSets = _TournamentBlock._playedSetsFor(m);

    final statusText = switch (m.status) {
      MatchStatus.upcoming => 'Por empezar',
      MatchStatus.live =>
        '${m.currentSet}.º · ${formatDurationSeconds(m.currentSetElapsedSeconds)}',
      MatchStatus.finished => 'Final',
    };
    final statusColor = switch (m.status) {
      MatchStatus.upcoming => sp.brand,
      MatchStatus.live => sp.live,
      MatchStatus.finished => sp.muted,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 78,
                    child: Column(
                      children: [
                        Text(
                          'Día ${m.startTime.day}',
                          style: context.type.labelSmall?.copyWith(
                            color: sp.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _formatTimeAmPm(m.startTime),
                          style: context.type.labelSmall?.copyWith(
                            fontFeatures: kTabular,
                            fontWeight: FontWeight.w700,
                            color: sp.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFeatures: kTabular,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: sp.line,
                    margin: const EdgeInsets.only(right: 12),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _teamLine(
                          context,
                          isLocal: true,
                          playedSets: playedSets,
                        ),
                        const SizedBox(height: 6),
                        _teamLine(
                          context,
                          isLocal: false,
                          playedSets: playedSets,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (m.recentEvent.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 79),
                  child: Text(
                    m.recentEvent,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.type.labelSmall?.copyWith(color: sp.muted),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamLine(
    BuildContext context, {
    required bool isLocal,
    required List<SetStatsData> playedSets,
  }) {
    final sp = context.sp;
    final m = match;
    final team = isLocal ? m.localTeam : m.visitTeam;
    final sets = isLocal ? m.localSetsWon : m.visitSetsWon;
    final oppSets = isLocal ? m.visitSetsWon : m.localSetsWon;
    final live = m.isLive;
    final upcoming = m.isUpcoming;
    final lostMatch = m.isMatchFinished && sets < oppSets;
    final serving = live && (m.isLocalServing == isLocal);

    return Row(
      children: [
        TeamCrest(
          shortName: team.shortName,
          color: Color(team.colorValue),
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  team.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: lostMatch ? sp.muted : sp.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (serving) ...[
                const SizedBox(width: 6),
                Icon(Icons.sports_volleyball, size: 12, color: sp.brand),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 22,
          child: Text(
            '$sets',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: upcoming
                  ? sp.muted
                  : (live ? sp.live : (lostMatch ? sp.muted : sp.ink)),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontFeatures: kTabular,
            ),
          ),
        ),
        const SizedBox(width: 8),
        for (var i = 0; i < setColumns; i++)
          SizedBox(
            width: 24,
            child: i < playedSets.length
                ? Text(
                    '${isLocal ? playedSets[i].localScore : playedSets[i].visitScore}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: upcoming
                          ? sp.faint
                          : (!playedSets[i].isCompleted
                              ? sp.live
                              : ((isLocal
                                      ? playedSets[i].localScore >
                                          playedSets[i].visitScore
                                      : playedSets[i].visitScore >
                                          playedSets[i].localScore)
                                  ? sp.ink
                                  : sp.faint)),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      fontFeatures: kTabular,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: sp.faint),
              const SizedBox(height: 14),
              Text(title,
                  textAlign: TextAlign.center,
                  style: context.type.headlineSmall),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: context.type.bodyMedium?.copyWith(color: sp.muted),
              ),
              if (action != null) ...[
                const SizedBox(height: 20),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
