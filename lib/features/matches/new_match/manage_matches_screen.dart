import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../core/widgets/sp_widgets.dart';
import '../../../data/match_repository.dart';
import '../../../models/match_model.dart';
import 'new_match_screen.dart';

class ManageMatchesScreen extends StatefulWidget {
  final MatchRepository repository;
  const ManageMatchesScreen({super.key, required this.repository});

  @override
  State<ManageMatchesScreen> createState() => _ManageMatchesScreenState();
}

class _ManageMatchesScreenState extends State<ManageMatchesScreen> {
  late final Stream<List<MatchModel>> _stream = widget.repository
      .watchMatches();
  bool _seeding = false;

  void _newMatch() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NewMatchScreen(repository: widget.repository),
      ),
    );
  }

  Future<bool> _confirmDelete(MatchModel m) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Borrar partido?'),
        content: Text(
          '${m.localTeamName} vs ${m.visitTeamName}\n${_when(m.startTime)}\n\n'
          'Se borran su marcador y estadísticas. Los equipos y el torneo se '
          'conservan. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.sp.live,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _delete(MatchModel m) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.repository.deleteMatch(m.id);
      messenger.showSnackBar(
        glassSnackBar(
          'Partido borrado: ${m.localTeamShort} vs ${m.visitTeamShort}',
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(glassSnackBar('No se pudo borrar: $e'));
    }
  }

  Future<void> _confirmAndSeed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Restaurar datos de ejemplo?'),
        content: const Text(
          'Vuelven a crearse los partidos, equipos y torneo de ejemplo '
          '(Tigres vs Borregos y FIME vs FACPYA) con el marcador en 0-0. '
          'Tus partidos no se tocan, pero si usan esos equipos, estos '
          'vuelven a sus datos de ejemplo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _seeding = true);
    try {
      await widget.repository.seedSampleData();
      messenger.showSnackBar(
        glassSnackBar(
          'Datos de ejemplo restaurados',
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(glassSnackBar('No se pudo restaurar: $e'));
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  static String _when(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.day)}/${two(t.month)}/${t.year} · '
        '${two(t.hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    return Scaffold(
      appBar: AppBar(title: const Text('Administrar partidos')),
      body: StreamBuilder<List<MatchModel>>(
        stream: _stream,
        builder: (context, snap) {
          final matches = snap.data ?? const <MatchModel>[];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  12,
                  14,
                  12,
                  28 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  FilledButton.icon(
                    onPressed: _newMatch,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Nuevo partido'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'Partidos',
                    trailing: Text(
                      '${matches.length}',
                      style: context.type.labelMedium,
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
                    child: !snap.hasData
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            ),
                          )
                        : matches.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'No hay partidos. Crea uno con «Nuevo partido».',
                              style: context.type.bodySmall,
                            ),
                          )
                        : Column(
                            children: [
                              for (var i = 0; i < matches.length; i++) ...[
                                if (i > 0) const Divider(),
                                _row(context, matches[i]),
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Desliza un partido hacia la izquierda o toca el bote '
                      'para borrarlo.',
                      style: context.type.labelSmall,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton.icon(
                      onPressed: _seeding ? null : _confirmAndSeed,
                      icon: _seeding
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: sp.muted,
                              ),
                            )
                          : const Icon(Icons.restart_alt_rounded, size: 18),
                      label: const Text('Restaurar datos de ejemplo'),
                      style: TextButton.styleFrom(foregroundColor: sp.muted),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, MatchModel m) {
    final sp = context.sp;
    final (statusText, statusColor) = switch (m.status) {
      MatchStatus.upcoming => ('Por empezar', sp.brand),
      MatchStatus.live => ('En vivo', sp.live),
      MatchStatus.finished => (
        'Final ${m.localSetsWon}-${m.visitSetsWon}',
        sp.muted,
      ),
    };
    return Dismissible(
      key: ValueKey(m.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(m),
      onDismissed: (_) => _delete(m),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: sp.live.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.delete_outline_rounded, color: sp.live),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            TeamCrest(
              shortName: m.localTeamShort,
              color: Color(m.localTeam.colorValue),
              size: 26,
            ),
            const SizedBox(width: 4),
            TeamCrest(
              shortName: m.visitTeamShort,
              color: Color(m.visitTeam.colorValue),
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${m.localTeamName} vs ${m.visitTeamName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.type.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(text: ' · ${_when(m.startTime)}'),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.type.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Borrar partido',
              onPressed: () async {
                if (await _confirmDelete(m)) await _delete(m);
              },
              icon: Icon(Icons.delete_outline_rounded, color: sp.faint),
            ),
          ],
        ),
      ),
    );
  }
}
