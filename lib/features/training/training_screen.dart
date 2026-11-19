import 'package:material_ui/material_ui.dart';

import '../../core/widgets/glass_widgets.dart';
import 'agenda/agenda_view.dart';
import 'agenda/schedule_store.dart';
import 'exercises_view.dart';
import 'training_progress_store.dart';

/// Módulo de entrenamiento: agenda semanal por persona y ejercicios del día.
/// Todo se guarda en el teléfono; no depende de Firebase ni de partidos.
class TrainingScreen extends StatelessWidget {
  final TrainingProgressStore store;
  final ScheduleStore scheduleStore;

  const TrainingScreen({
    super.key,
    this.store = const TrainingProgressStore(),
    this.scheduleStore = const ScheduleStore(),
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(titleSpacing: 20, title: const Text('Entrenamiento')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420, maxHeight: 40),
                child: const GlassTabBar(labels: ['Agenda', 'Ejercicios']),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  AgendaView(store: scheduleStore),
                  ExercisesView(store: store),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
