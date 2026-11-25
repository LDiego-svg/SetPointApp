import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../core/widgets/sp_widgets.dart';
import '../../../data/match_repository.dart';
import '../../../data/seed_data.dart';
import '../../../models/match_model.dart';
import 'ids.dart';
import 'new_team_sheet.dart';

class NewMatchScreen extends StatefulWidget {
  final MatchRepository repository;
  const NewMatchScreen({super.key, required this.repository});

  @override
  State<NewMatchScreen> createState() => _NewMatchScreenState();
}

const _newItem = '__nuevo__';

class _NewMatchScreenState extends State<NewMatchScreen> {
  late final Future<void> _loading = _load();

  final List<TeamInfo> _teams = [];
  final List<TeamInfo> _newTeams = [];
  final List<TournamentInfo> _tournaments = [];
  TournamentInfo? _newTournament;

  String? _localId;
  String? _visitId;
  String? _tournamentId;
  final _stage = TextEditingController();
  final _venue = TextEditingController();
  late DateTime _date = DateUtils.dateOnly(DateTime.now());
  TimeOfDay _time = TimeOfDay(hour: (DateTime.now().hour + 1) % 24, minute: 0);

  // Fuerza a reconstruir los dropdowns si se cancela el alta.
  int _rev = 0;

  Future<void> _load() async {
    final results = await Future.wait([
      widget.repository.loadTeams(),
      widget.repository.loadTournaments(),
    ]);
    _teams.addAll(results[0] as List<TeamInfo>);
    _tournaments.addAll(results[1] as List<TournamentInfo>);
    if (_tournaments.isNotEmpty) _tournamentId = _tournaments.first.id;
  }

  @override
  void dispose() {
    _stage.dispose();
    _venue.dispose();
    super.dispose();
  }

  TeamInfo? _team(String? id) {
    for (final t in _teams) {
      if (t.id == id) return t;
    }
    return null;
  }

  bool get _canSave =>
      _localId != null &&
      _visitId != null &&
      _localId != _visitId &&
      _tournamentId != null;

  Future<void> _pickTeam({required bool isLocal}) async {
    final team = await showNewTeamSheet(
      context,
      takenIds: {for (final t in _teams) t.id},
    );
    setState(() => _rev++);
    if (team == null) return;
    setState(() {
      _teams.add(team);
      _newTeams.add(team);
      if (isLocal) {
        _localId = team.id;
      } else {
        _visitId = team.id;
      }
    });
  }

  Future<void> _addTournament() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _NewTournamentDialog(),
    );
    setState(() => _rev++);
    if (name == null || name.trim().isEmpty) return;
    final tournament = TournamentInfo(
      id: uniqueId(slugify(name.trim()), {for (final t in _tournaments) t.id}),
      name: name.trim(),
      category: 'México',
      season: '${DateTime.now().year}',
    );
    setState(() {
      if (_newTournament != null) _tournaments.remove(_newTournament);
      _tournaments.add(tournament);
      _newTournament = tournament;
      _tournamentId = tournament.id;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    final local = _team(_localId)!;
    final visit = _team(_visitId)!;
    final tournament = _tournaments.firstWhere((t) => t.id == _tournamentId);
    final start = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    final stage = _stage.text.trim();
    final venue = _venue.text.trim();
    final match = SeedData.match(
      tournament,
      local,
      visit,
      id: matchId(local.id, visit.id, start),
      stage: stage.isEmpty ? 'Amistoso' : stage,
      venue: venue.isEmpty ? 'Por definir' : venue,
      startTime: start,
    );

    // No se espera a Firestore para no bloquear el cierre sin conexión.
    final messenger = ScaffoldMessenger.of(context);
    widget.repository
        .createMatch(
          match,
          newTeams: [
            for (final t in _newTeams)
              if (t.id == local.id || t.id == visit.id) t,
          ],
          newTournament: _newTournament?.id == tournament.id
              ? _newTournament
              : null,
        )
        .catchError((Object e) {
          messenger.showSnackBar(glassSnackBar('No se pudo crear: $e'));
        });
    messenger.showSnackBar(
      glassSnackBar(
        'Partido creado: ${local.shortName} vs ${visit.shortName}',
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo partido'),
        actions: [
          TextButton(
            onPressed: _canSave ? _save : null,
            style: TextButton.styleFrom(
              foregroundColor: context.sp.onHeader,
              disabledForegroundColor: context.sp.onHeader.withValues(
                alpha: 0.45,
              ),
            ),
            child: const Text(
              'Guardar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<void>(
        future: _loading,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2.4),
            );
          }
          if (snap.hasError) {
            return Center(child: Text('No se pudieron leer los equipos.'));
          }
          return _buildForm(context);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final sp = context.sp;
    final sameTeam = _localId != null && _localId == _visitId;
    String two(int n) => n.toString().padLeft(2, '0');
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
            SectionCard(
              title: 'Equipos',
              child: Column(
                children: [
                  _teamField(label: 'Local', isLocal: true),
                  const SizedBox(height: 12),
                  _teamField(label: 'Visitante', isLocal: false),
                  if (sameTeam) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Elige dos equipos distintos.',
                      style: context.type.bodySmall?.copyWith(color: sp.live),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Detalles',
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey('torneo-$_tournamentId-$_rev'),
                    initialValue: _tournamentId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Torneo'),
                    items: [
                      for (final t in _tournaments)
                        DropdownMenuItem(value: t.id, child: Text(t.name)),
                      const DropdownMenuItem(
                        value: _newItem,
                        child: Text('＋ Nuevo torneo…'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == _newItem) {
                        _addTournament();
                      } else {
                        setState(() => _tournamentId = v);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _stage,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Fase o jornada',
                      hintText: 'Jornada 3',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _venue,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Sede',
                      hintText: 'Gimnasio…',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.event_rounded, size: 18),
                          label: Text(
                            '${two(_date.day)}/${two(_date.month)}/${_date.year}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.schedule_rounded, size: 18),
                          label: Text(
                            '${two(_time.hour)}:${two(_time.minute)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamField({required String label, required bool isLocal}) {
    final value = isLocal ? _localId : _visitId;
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$value-$_rev'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final t in _teams)
          DropdownMenuItem(
            value: t.id,
            child: Row(
              children: [
                TeamCrest(
                  shortName: t.shortName,
                  color: Color(t.colorValue),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(t.name, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        const DropdownMenuItem(value: _newItem, child: Text('＋ Nuevo equipo…')),
      ],
      onChanged: (v) {
        if (v == _newItem) {
          _pickTeam(isLocal: isLocal);
        } else {
          setState(() => isLocal ? _localId = v : _visitId = v);
        }
      },
    );
  }
}

class _NewTournamentDialog extends StatefulWidget {
  const _NewTournamentDialog();

  @override
  State<_NewTournamentDialog> createState() => _NewTournamentDialogState();
}

class _NewTournamentDialogState extends State<_NewTournamentDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo torneo'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Nombre'),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_ctrl.text),
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
