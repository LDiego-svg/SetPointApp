import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/sp_widgets.dart';
import '../../../models/match_model.dart';
import 'ids.dart';

Future<TeamInfo?> showNewTeamSheet(
  BuildContext context, {
  required Set<String> takenIds,
}) {
  return showModalBottomSheet<TeamInfo>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _NewTeamSheet(takenIds: takenIds),
  );
}

const _teamColors = [
  0xFFF2A900, 0xFFFF6B00, 0xFFE5243B, 0xFF9E1B32, 0xFFE91E63, 0xFF7B2CBF, //
  0xFF3449E8, 0xFF1E6FD9, 0xFF0F9D9A, 0xFF007A33, 0xFF6D4C41, 0xFF1D1F24, //
];

class _NewTeamSheet extends StatefulWidget {
  final Set<String> takenIds;
  const _NewTeamSheet({required this.takenIds});

  @override
  State<_NewTeamSheet> createState() => _NewTeamSheetState();
}

class _NewTeamSheetState extends State<_NewTeamSheet> {
  final _name = TextEditingController();
  final _short = TextEditingController();
  final _players = TextEditingController();
  int _color = _teamColors.first;

  @override
  void dispose() {
    _name.dispose();
    _short.dispose();
    _players.dispose();
    super.dispose();
  }

  // Formato por línea: "10 J. Martínez, Armador" (rol opcional).
  static List<TeamPlayer> _parsePlayers(String text) {
    final line = RegExp(r'^\s*(\d+)\s+([^,]+?)\s*(?:,\s*(.+?))?\s*$');
    return [
      for (final raw in text.split('\n'))
        if (line.firstMatch(raw) case final m?)
          TeamPlayer(
            dorsal: int.parse(m.group(1)!),
            name: m.group(2)!,
            role: m.group(3) ?? '',
          ),
    ];
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final short = _short.text.trim().toUpperCase();
    Navigator.of(context).pop(
      TeamInfo(
        id: uniqueId(slugify(name), widget.takenIds),
        name: name,
        shortName: short.isEmpty ? defaultShortName(name) : short,
        colorValue: _color,
        players: _parsePlayers(_players.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final players = _parsePlayers(_players.text).length;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom +
            20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nuevo equipo', style: context.type.headlineSmall),
            const SizedBox(height: 16),
            Row(
              children: [
                TeamCrest(
                  shortName: _short.text.trim().isEmpty
                      ? defaultShortName(_name.text)
                      : _short.text.trim().toUpperCase(),
                  color: Color(_color),
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _name,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 76,
                  child: TextField(
                    controller: _short,
                    maxLength: 4,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Siglas',
                      counterText: '',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text('Color', style: context.type.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in _teamColors)
                  Pressable(
                    onTap: () => setState(() => _color = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: c == _color ? sp.ink : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _players,
              minLines: 3,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: 'Jugadores (opcional)',
                hintText: '10 J. Martínez, Armador\n7 L. Cavazos, Opuesto',
                helperText:
                    'Uno por línea: dorsal, nombre y rol. Los 6 primeros '
                    'forman la alineación inicial.',
                helperMaxLines: 2,
                suffixText: players > 0 ? '$players' : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _name.text.trim().isEmpty ? null : _save,
              child: const Text('Agregar equipo'),
            ),
          ],
        ),
      ),
    );
  }
}
