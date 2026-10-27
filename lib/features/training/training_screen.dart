import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/sp_widgets.dart';

class TrainingDrill {
  final String id;
  final String title;
  final String category; // 'Saque', 'Recepción', 'Remate', 'Físico'
  final String setsAndReps;
  final String intensity;
  final String restSuggestion;
  bool isCompleted;

  TrainingDrill({
    required this.id,
    required this.title,
    required this.category,
    required this.setsAndReps,
    required this.intensity,
    required this.restSuggestion,
    this.isCompleted = false,
  });
}

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  static const List<String> _categories = [
    'Todos',
    'Saque',
    'Recepción',
    'Remate',
    'Físico',
  ];

  int _selectedCategoryIndex = 0;

  Timer? _timer;
  int _selectedPresetSeconds = 60;
  int _remainingSeconds = 60;
  bool _isRunning = false;

  final List<TrainingDrill> _drills = [
    TrainingDrill(
      id: 'd1',
      title: 'Saque flotante dirigido a zonas 1 y 5',
      category: 'Saque',
      setsAndReps: '4 series × 10 saques efectivos',
      intensity: 'Media-alta',
      restSuggestion: '45 s descanso',
      isCompleted: true,
    ),
    TrainingDrill(
      id: 'd2',
      title: 'Saque en suspensión de potencia',
      category: 'Saque',
      setsAndReps: '4 series × 8 repeticiones',
      intensity: 'Alta',
      restSuggestion: '60 s descanso',
      isCompleted: false,
    ),
    TrainingDrill(
      id: 'd3',
      title: 'Recepción en W con desplazamiento lateral',
      category: 'Recepción',
      setsAndReps: '3 series × 15 recepciones perfectas (#)',
      intensity: 'Media',
      restSuggestion: '45 s descanso',
      isCompleted: true,
    ),
    TrainingDrill(
      id: 'd4',
      title: 'Defensa de balón rápido y control al armador',
      category: 'Recepción',
      setsAndReps: '4 series × 12 repeticiones',
      intensity: 'Alta',
      restSuggestion: '60 s descanso',
      isCompleted: false,
    ),
    TrainingDrill(
      id: 'd5',
      title: 'Ataque diagonal y línea desde zona 4',
      category: 'Remate',
      setsAndReps: '4 series × 10 remates contra doble bloqueo',
      intensity: 'Alta',
      restSuggestion: '60 s descanso',
      isCompleted: false,
    ),
    TrainingDrill(
      id: 'd6',
      title: 'Ataque zaguero (pipe) por zona 6',
      category: 'Remate',
      setsAndReps: '3 series × 8 ataques efectivos',
      intensity: 'Alta',
      restSuggestion: '60 s descanso',
      isCompleted: false,
    ),
    TrainingDrill(
      id: 'd7',
      title: 'Pliometría de salto al bloqueo + caída reactiva',
      category: 'Físico',
      setsAndReps: '4 series × 12 saltos máximos',
      intensity: 'Máxima',
      restSuggestion: '90 s descanso',
      isCompleted: false,
    ),
    TrainingDrill(
      id: 'd8',
      title: 'Circuito de agilidad suiza en media cancha',
      category: 'Físico',
      setsAndReps: '5 series × 30 segundos a tope',
      intensity: 'Máxima',
      restSuggestion: '60 s descanso',
      isCompleted: false,
    ),
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPauseTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
      return;
    }

    if (_remainingSeconds == 0) {
      setState(() => _remainingSeconds = _selectedPresetSeconds);
    }

    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        setState(() => _isRunning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Descanso terminado. Listo para la siguiente serie.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _selectedPresetSeconds;
    });
  }

  void _setTimerPreset(int seconds) {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _selectedPresetSeconds = seconds;
      _remainingSeconds = seconds;
    });
  }

  String _formatTime(int totalSeconds) {
    final int mins = totalSeconds ~/ 60;
    final int secs = totalSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  List<TrainingDrill> get _filteredDrills {
    final cat = _categories[_selectedCategoryIndex];
    if (cat == 'Todos') return _drills;
    return _drills.where((d) => d.category == cat).toList();
  }

  @override
  Widget build(BuildContext context) {
    final int completedCount = _drills.where((d) => d.isCompleted).length;
    final int totalCount = _drills.length;
    final double progress =
        totalCount == 0 ? 0.0 : completedCount / totalCount;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text('Entrenamiento'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 28),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: PillTabs(
                  labels: _categories,
                  selected: _selectedCategoryIndex,
                  onChanged: (i) => setState(() => _selectedCategoryIndex = i),
                ),
              ),
              const SizedBox(height: 12),
              _buildProgressAndTimerRow(
                context,
                completedCount: completedCount,
                totalCount: totalCount,
                progress: progress,
              ),
              const SizedBox(height: 12),
              _buildDrillsCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressAndTimerRow(
    BuildContext context, {
    required int completedCount,
    required int totalCount,
    required double progress,
  }) {
    final sp = context.sp;
    final int pct = (progress * 100).round();

    return SectionCard(
      title: 'Sesión del día',
      trailing: Text(
        '$completedCount de $totalCount · $pct%',
        style: TextStyle(
          color: sp.brand,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          fontFeatures: kTabular,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: sp.raised,
              valueColor: AlwaysStoppedAnimation<Color>(sp.brand),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: sp.raised,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Descanso entre series',
                            style: context.type.labelMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(_remainingSeconds),
                            style: TextStyle(
                              color: _isRunning ? sp.brand : sp.ink,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              fontFeatures: kTabular,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final sec in const [30, 60, 90])
                          Pressable(
                            onTap: () => _setTimerPreset(sec),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedPresetSeconds == sec
                                    ? sp.brand
                                    : sp.card,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: _selectedPresetSeconds == sec
                                      ? sp.brand
                                      : sp.line,
                                ),
                              ),
                              child: Text(
                                '${sec}s',
                                style: TextStyle(
                                  color: _selectedPresetSeconds == sec
                                      ? sp.onBrand
                                      : sp.muted,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: kTabular,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton.outlined(
                      tooltip: 'Reiniciar',
                      onPressed: _resetTimer,
                      icon: const Icon(Icons.replay_rounded, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _startPauseTimer,
                        icon: Icon(
                          _isRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 20,
                        ),
                        label: Text(_isRunning ? 'Pausar' : 'Iniciar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrillsCard(BuildContext context) {
    final sp = context.sp;
    final drills = _filteredDrills;

    return SectionCard(
      title: 'Ejercicios',
      trailing: Text(
        '${drills.length} ejercicios',
        style: context.type.labelMedium,
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        children: [
          for (var i = 0; i < drills.length; i++) ...[
            if (i > 0) const Divider(),
            _DrillRow(
              drill: drills[i],
              onToggle: () {
                setState(() => drills[i].isCompleted = !drills[i].isCompleted);
              },
              accentColor: sp.brand,
            ),
          ],
        ],
      ),
    );
  }
}

class _DrillRow extends StatelessWidget {
  final TrainingDrill drill;
  final VoidCallback onToggle;
  final Color accentColor;

  const _DrillRow({
    required this.drill,
    required this.onToggle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    return Pressable(
      onTap: onToggle,
      pressedScale: 0.985,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                drill.isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: drill.isCompleted ? sp.win : sp.faint,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drill.title,
                    style: TextStyle(
                      color: drill.isCompleted ? sp.muted : sp.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      decoration: drill.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${drill.category} · ${drill.setsAndReps} · ${drill.restSuggestion}',
                    style: context.type.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}