import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import 'schedule_models.dart';

/// Avatar con las iniciales de la persona.
class PersonAvatar extends StatelessWidget {
  final Athlete athlete;
  final double size;
  const PersonAvatar({super.key, required this.athlete, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: sp.brand.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Text(
        athlete.initials,
        style: TextStyle(
          color: sp.brand,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}

/// Hoja para cambiar de persona, agregar una nueva o borrarla. Los cambios se
/// avisan al padre con los callbacks; la hoja refleja la lista actualizada.
Future<void> showPersonSheet(
  BuildContext context, {
  required List<Athlete> athletes,
  required String? selectedId,
  required ValueChanged<String> onSelect,
  required ValueChanged<Athlete> onAdd,
  required ValueChanged<String> onDelete,
  required VoidCallback onRestore,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PersonSheet(
      athletes: athletes,
      selectedId: selectedId,
      onSelect: onSelect,
      onAdd: onAdd,
      onDelete: onDelete,
      onRestore: onRestore,
    ),
  );
}

class _PersonSheet extends StatefulWidget {
  final List<Athlete> athletes;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final ValueChanged<Athlete> onAdd;
  final ValueChanged<String> onDelete;
  final VoidCallback onRestore;

  const _PersonSheet({
    required this.athletes,
    required this.selectedId,
    required this.onSelect,
    required this.onAdd,
    required this.onDelete,
    required this.onRestore,
  });

  @override
  State<_PersonSheet> createState() => _PersonSheetState();
}

class _PersonSheetState extends State<_PersonSheet> {
  late final List<Athlete> _athletes = List.of(widget.athletes);

  Future<void> _add() async {
    final athlete = await showDialog<Athlete>(
      context: context,
      builder: (_) => const _NewPersonDialog(),
    );
    if (athlete == null || !mounted) return;
    widget.onAdd(athlete);
    Navigator.of(context).pop();
  }

  Future<void> _delete(Athlete a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Borrar a ${a.name}?'),
        content: const Text('Se borra también su agenda.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    widget.onDelete(a.id);
    setState(() => _athletes.removeWhere((x) => x.id == a.id));
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text('Ver agenda de…', style: context.type.headlineSmall),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final a in _athletes)
                    ListTile(
                      leading: PersonAvatar(athlete: a, size: 40),
                      title: Text(a.name),
                      subtitle: Text(
                        [
                          if (a.role.isNotEmpty) a.role,
                          '${a.blocks.length} actividades',
                        ].join(' · '),
                      ),
                      selected: a.id == widget.selectedId,
                      onTap: () {
                        widget.onSelect(a.id);
                        Navigator.of(context).pop();
                      },
                      trailing: _athletes.length > 1
                          ? IconButton(
                              tooltip: 'Borrar persona',
                              onPressed: () => _delete(a),
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: sp.faint,
                              ),
                            )
                          : null,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.person_add_alt_rounded),
              label: const Text('Agregar persona'),
            ),
            TextButton(
              onPressed: () {
                widget.onRestore();
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: sp.muted),
              child: const Text('Restaurar agendas de ejemplo'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo con sus propios controladores (se liberan al desmontarse, no al
/// cerrar, porque la animación de salida aún los usa).
class _NewPersonDialog extends StatefulWidget {
  const _NewPersonDialog();

  @override
  State<_NewPersonDialog> createState() => _NewPersonDialogState();
}

class _NewPersonDialogState extends State<_NewPersonDialog> {
  final _name = TextEditingController();
  final _role = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(
      Athlete(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        role: _role.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva persona'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _role,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Rol (opcional)',
              hintText: 'Central · #14',
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Agregar')),
      ],
    );
  }
}
