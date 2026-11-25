import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import 'schedule_models.dart';

typedef BlockSheetResult = ({List<ScheduleBlock> save, bool delete});

Future<BlockSheetResult?> showBlockSheet(
  BuildContext context, {
  ScheduleBlock? initial,
  required int defaultDay,
}) {
  return showModalBottomSheet<BlockSheetResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _BlockSheet(initial: initial, defaultDay: defaultDay),
  );
}

class _BlockSheet extends StatefulWidget {
  final ScheduleBlock? initial;
  final int defaultDay;
  const _BlockSheet({required this.initial, required this.defaultDay});

  @override
  State<_BlockSheet> createState() => _BlockSheetState();
}

class _BlockSheetState extends State<_BlockSheet> {
  late final ScheduleBlock? _initial = widget.initial;
  late ActivityType _type = _initial?.type ?? ActivityType.entrenamiento;
  late final _title = TextEditingController(text: _initial?.title ?? '');
  late final _place = TextEditingController(text: _initial?.place ?? '');
  late final Set<int> _days = {_initial?.weekday ?? widget.defaultDay};
  late int _start = _initial?.start ?? 9 * 60;
  late int _end = _initial?.end ?? 10 * 60;

  bool get _editing => _initial != null;
  bool get _valid => _days.isNotEmpty && _end > _start;

  @override
  void dispose() {
    _title.dispose();
    _place.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool start}) async {
    final current = start ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    setState(() {
      if (start) {
        final length = _end - _start;
        _start = minutes;
        if (_end <= _start) _end = (_start + length).clamp(1, 24 * 60);
      } else {
        _end = minutes;
      }
    });
  }

  void _save() {
    final title = _title.text.trim();
    final base = ScheduleBlock(
      id: _initial?.id ?? '${DateTime.now().microsecondsSinceEpoch}',
      weekday: _days.first,
      start: _start,
      end: _end,
      type: _type,
      title: title.isEmpty ? _type.label : title,
      place: _place.text.trim(),
    );
    final days = _days.toList()..sort();
    Navigator.of(context).pop((
      save: [
        for (var i = 0; i < days.length; i++)
          base.copyWith(
            weekday: days[i],
            id: i == 0 ? base.id : '${base.id}-${days[i]}',
          ),
      ],
      delete: false,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
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
            Text(
              _editing ? 'Editar actividad' : 'Nueva actividad',
              style: context.type.headlineSmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in ActivityType.values)
                  ChoiceChip(
                    selected: t == _type,
                    onSelected: (_) => setState(() => _type = t),
                    avatar: Icon(
                      t.icon,
                      size: 18,
                      color: t == _type ? t.color : sp.muted,
                    ),
                    label: Text(t.label),
                    selectedColor: t.color.withValues(alpha: 0.16),
                    showCheckmark: false,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Título',
                hintText: _type.label,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _place,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Lugar (opcional)'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(start: true),
                    icon: const Icon(Icons.schedule_rounded, size: 18),
                    label: Text('Inicio ${formatMinutes(_start)}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(start: false),
                    icon: const Icon(Icons.schedule_rounded, size: 18),
                    label: Text('Fin ${formatMinutes(_end)}'),
                  ),
                ),
              ],
            ),
            if (_end <= _start) ...[
              const SizedBox(height: 6),
              Text(
                'La hora de fin debe ser después del inicio.',
                style: context.type.bodySmall?.copyWith(color: sp.live),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              _editing ? 'Día' : 'Días (se repite cada semana)',
              style: context.type.labelMedium,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var d = 1; d <= 7; d++)
                  _DayToggle(
                    letter: weekdayLetters[d - 1],
                    selected: _days.contains(d),
                    onTap: () => setState(() {
                      if (_editing) {
                        _days
                          ..clear()
                          ..add(d);
                      } else if (!_days.remove(d)) {
                        _days.add(d);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _valid ? _save : null,
              child: Text(_editing ? 'Guardar cambios' : 'Agregar'),
            ),
            if (_editing) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () =>
                    Navigator.of(context)
                        .pop((save: const <ScheduleBlock>[], delete: true)),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Borrar actividad'),
                style: TextButton.styleFrom(foregroundColor: sp.live),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayToggle extends StatelessWidget {
  final String letter;
  final bool selected;
  final VoidCallback onTap;
  const _DayToggle({
    required this.letter,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? sp.brand : sp.raised,
          shape: BoxShape.circle,
        ),
        child: Text(
          letter,
          style: TextStyle(
            color: selected ? sp.onBrand : sp.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
