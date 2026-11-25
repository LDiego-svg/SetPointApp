import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/sp_widgets.dart';
import 'agenda_block_tile.dart';
import 'block_sheet.dart';
import 'person_sheet.dart';
import 'sample_schedule.dart';
import 'schedule_models.dart';
import 'schedule_store.dart';

class AgendaView extends StatefulWidget {
  final ScheduleStore store;
  const AgendaView({super.key, this.store = const ScheduleStore()});

  @override
  State<AgendaView> createState() => _AgendaViewState();
}

class _AgendaViewState extends State<AgendaView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Athlete>? _athletes;
  String? _selectedId;
  int _day = DateTime.now().weekday;
  Timer? _minuteTicker;

  @override
  void initState() {
    super.initState();
    _load();
    _minuteTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && _day == DateTime.now().weekday) setState(() {});
    });
  }

  @override
  void dispose() {
    _minuteTicker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final athletes = await widget.store.load();
    final saved = await widget.store.loadSelected();
    if (!mounted) return;
    setState(() {
      _athletes = athletes;
      _selectedId = athletes.any((a) => a.id == saved)
          ? saved
          : (athletes.isEmpty ? null : athletes.first.id);
    });
  }

  Athlete? get _current {
    for (final a in _athletes ?? const <Athlete>[]) {
      if (a.id == _selectedId) return a;
    }
    return null;
  }

  void _update(List<Athlete> athletes) {
    setState(() => _athletes = athletes);
    widget.store.save(athletes);
  }

  void _select(String id) {
    setState(() => _selectedId = id);
    widget.store.saveSelected(id);
  }

  void _openPeople() {
    showPersonSheet(
      context,
      athletes: _athletes!,
      selectedId: _selectedId,
      onSelect: _select,
      onAdd: (a) {
        _update([..._athletes!, a]);
        _select(a.id);
      },
      onDelete: (id) {
        final rest = _athletes!.where((a) => a.id != id).toList();
        _update(rest);
        if (id == _selectedId && rest.isNotEmpty) _select(rest.first.id);
      },
      onRestore: () {
        final sample = sampleAthletes();
        _update(sample);
        _select(sample.first.id);
      },
    );
  }

  Future<void> _editBlock([ScheduleBlock? block]) async {
    final person = _current;
    if (person == null) return;
    final result = await showBlockSheet(
      context,
      initial: block,
      defaultDay: _day,
    );
    if (result == null) return;
    final blocks = person.blocks.where((b) => b.id != block?.id).toList();
    if (!result.delete) blocks.addAll(result.save);
    _update([
      for (final a in _athletes!)
        a.id == person.id ? a.copyWith(blocks: blocks) : a,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final athletes = _athletes;
    if (athletes == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
    }
    final person = _current;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            12,
            12,
            12,
            28 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            _PersonCard(person: person, onChange: _openPeople),
            const SizedBox(height: 12),
            _WeekStrip(
              selected: _day,
              person: person,
              onChanged: (d) => setState(() => _day = d),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.03),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey('${person?.id}-$_day'),
                child: _DayAgenda(
                  person: person,
                  day: _day,
                  onTapBlock: _editBlock,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (person != null)
              OutlinedButton.icon(
                onPressed: () => _editBlock(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Agregar actividad'),
              ),
          ],
        ),
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final Athlete? person;
  final VoidCallback onChange;
  const _PersonCard({required this.person, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final p = person;
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        children: [
          if (p != null) PersonAvatar(athlete: p) else const SizedBox(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p?.name ?? 'Sin personas',
                  style: context.type.titleMedium,
                ),
                if (p != null && p.role.isNotEmpty)
                  Text(p.role, style: context.type.bodySmall),
              ],
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: onChange,
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  final int selected;
  final Athlete? person;
  final ValueChanged<int> onChanged;
  const _WeekStrip({
    required this.selected,
    required this.person,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final now = DateTime.now();
    final monday = DateUtils.dateOnly(now)
        .subtract(Duration(days: now.weekday - 1));
    return Row(
      children: [
        for (var d = 1; d <= 7; d++)
          Expanded(
            child: Pressable(
              onTap: () => onChanged(d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: d == selected ? sp.brand : sp.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      weekdayLetters[d - 1],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: d == selected ? sp.onBrand : sp.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${monday.add(Duration(days: d - 1)).day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        fontFeatures: kTabular,
                        color: d == selected
                            ? sp.onBrand
                            : (d == now.weekday ? sp.brand : sp.ink),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (person?.blocksFor(d).isEmpty ?? true)
                            ? Colors.transparent
                            : (d == selected ? sp.onBrand : sp.faint),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DayAgenda extends StatelessWidget {
  final Athlete? person;
  final int day;
  final ValueChanged<ScheduleBlock> onTapBlock;
  const _DayAgenda({
    required this.person,
    required this.day,
    required this.onTapBlock,
  });

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final blocks = person?.blocksFor(day) ?? const <ScheduleBlock>[];
    final now = DateTime.now();
    final isToday = day == now.weekday;
    final nowMin = now.hour * 60 + now.minute;
    final totalMin = blocks.fold<int>(0, (s, b) => s + b.durationMinutes);
    final nextIndex = isToday ? blocks.indexWhere((b) => b.start > nowMin) : -1;

    return SectionCard(
      title: isToday ? 'Hoy · ${weekdayNames[day - 1]}' : weekdayNames[day - 1],
      trailing: blocks.isEmpty
          ? null
          : Text(
              '${blocks.length} act. · ${totalMin ~/ 60} h'
              '${totalMin % 60 > 0 ? ' ${totalMin % 60}' : ''}',
              style: context.type.labelMedium,
            ),
      child: blocks.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Icon(Icons.wb_sunny_outlined, color: sp.faint, size: 30),
                  const SizedBox(height: 8),
                  Text('Día libre', style: context.type.titleSmall),
                ],
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < blocks.length; i++)
                  AgendaBlockTile(
                    block: blocks[i],
                    isNow:
                        isToday &&
                        blocks[i].start <= nowMin &&
                        nowMin < blocks[i].end,
                    isNext: i == nextIndex,
                    progress: isToday
                        ? ((nowMin - blocks[i].start) /
                                  blocks[i].durationMinutes)
                              .clamp(0.0, 1.0)
                        : 0,
                    isLast: i == blocks.length - 1,
                    onTap: () => onTapBlock(blocks[i]),
                  ),
              ],
            ),
    );
  }
}
