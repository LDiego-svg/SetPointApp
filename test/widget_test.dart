import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:set_point/core/theme/app_theme.dart';
import 'package:set_point/core/widgets/live_clock.dart';
import 'package:set_point/data/in_memory_match_repository.dart';
import 'package:set_point/main.dart';
import 'package:set_point/models/match_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    AppTheme.useGoogleFonts = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SetPoint Sofascore flow, upcoming state, and set timer', (
    WidgetTester tester,
  ) async {
    final repo = InMemoryMatchRepository();

    await tester.pumpWidget(SetPointApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Aún no hay partidos'), findsOneWidget);
    await tester.tap(find.text('Crear partido de ejemplo'));
    await tester.pumpAndSettle();

    expect(find.text('Liga Universitaria de Voleibol'), findsOneWidget);
    expect(find.text('Tigres UANL'), findsOneWidget);
    expect(find.text('Borregos MTY'), findsOneWidget);
    expect(find.text('FIME'), findsOneWidget);
    expect(find.text('FACPYA'), findsOneWidget);
    expect(find.text('Por empezar 2'), findsOneWidget);
    expect(find.text('Por empezar'), findsWidgets);

    await tester.tap(find.text('Tigres UANL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Detalles'), findsOneWidget);
    expect(find.text('Estadísticas'), findsOneWidget);
    expect(find.text('Alineación'), findsOneWidget);
    expect(find.text('Partido por empezar'), findsOneWidget);
    expect(find.text('Iniciar partido'), findsOneWidget);

    await tester.tap(find.text('Iniciar partido'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(repo.matches['partido_demo']!['status'], 'live');
    expect(find.text('1.º set'), findsOneWidget);

    expect(repo.matches['partido_demo']!['localPoints'], 0);
    await tester.tap(find.text('Ataque').first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(repo.matches['partido_demo']!['localPoints'], 1);

    await tester.tap(find.text('Deshacer'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(repo.matches['partido_demo']!['localPoints'], 0);
  });

  test('Set timer records duration when a team wins the set', () {
    final start = DateTime(2026, 10, 24, 8, 30, 0);
    final match = MatchModel(
      id: 'm1',
      tournament: TournamentInfo.defaultTournament(),
      stage: 'Final',
      venue: 'Gimnasio',
      startTime: start,
      localTeam: const TeamInfo(
        id: 'a',
        name: 'Local',
        shortName: 'LOC',
        colorValue: 0xFF3449E8,
      ),
      visitTeam: const TeamInfo(
        id: 'b',
        name: 'Visita',
        shortName: 'VIS',
        colorValue: 0xFFE5243B,
      ),
      currentSet: 1,
      localSetsWon: 0,
      visitSetsWon: 0,
      localPoints: 24,
      visitPoints: 20,
      isLocalServing: true,
      isMatchStarted: false,
      isMatchFinished: false,
      setsHistory: [for (var i = 1; i <= 5; i++) SetStatsData(setNumber: i)],
      events: [],
      localLineup: const [],
      visitLineup: const [],
    );

    expect(match.status, MatchStatus.upcoming);
    match.startMatch(DateTime.now().subtract(const Duration(minutes: 22)));
    expect(match.status, MatchStatus.live);

    match.addPoint(isLocal: true, actionType: PointActionType.attack);

    expect(match.localSetsWon, 1);
    expect(match.currentSet, 2);
    expect(match.setsHistory[0].isCompleted, isTrue);
    expect(match.setsHistory[0].durationSeconds, greaterThanOrEqualTo(22 * 60));
  });

  testWidgets(
    'TrainingScreen timer controls do not overflow on narrow screens',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = InMemoryMatchRepository();
      await tester.pumpWidget(SetPointApp(repository: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Entrenamiento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ejercicios'));
      await tester.pumpAndSettle();

      expect(find.text('Descanso entre series'), findsOneWidget);
      expect(find.text('Iniciar'), findsOneWidget);

      await tester.tap(find.text('Iniciar'));
      await tester.pump();
      expect(find.text('Pausar'), findsOneWidget);

      await tester.tap(find.text('Pausar'));
      await tester.pump();
      expect(find.text('Iniciar'), findsOneWidget);
    },
  );

  testWidgets('Training progress starts empty and persists across restarts', (
    WidgetTester tester,
  ) async {
    // Alto suficiente para que la lista de ejercicios quepa sin desplazar.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    Future<void> openTraining() async {
      await tester.pumpWidget(
        SetPointApp(repository: InMemoryMatchRepository()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Entrenamiento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ejercicios'));
      await tester.pumpAndSettle();
    }

    await openTraining();
    expect(find.text('0 de 8 · 0%'), findsOneWidget);

    await tester.tap(find.text('Saque en suspensión de potencia'));
    await tester.pumpAndSettle();
    expect(find.text('1 de 8 · 13%'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await openTraining();
    expect(find.text('1 de 8 · 13%'), findsOneWidget);
  });

  test('Only played sets count: a 3-0 match shows three sets', () {
    final match = MatchModel(
      id: 'm2',
      tournament: TournamentInfo.defaultTournament(),
      stage: 'Final',
      venue: 'Gimnasio',
      startTime: DateTime(2026, 10, 24, 8, 30),
      localTeam: const TeamInfo(
        id: 'a',
        name: 'Local',
        shortName: 'LOC',
        colorValue: 0xFF3449E8,
      ),
      visitTeam: const TeamInfo(
        id: 'b',
        name: 'Visita',
        shortName: 'VIS',
        colorValue: 0xFFE5243B,
      ),
      currentSet: 1,
      localSetsWon: 0,
      visitSetsWon: 0,
      localPoints: 0,
      visitPoints: 0,
      isLocalServing: true,
      isMatchStarted: false,
      isMatchFinished: false,
      setsHistory: [for (var i = 1; i <= 5; i++) SetStatsData(setNumber: i)],
      events: [],
      localLineup: const [],
      visitLineup: const [],
    );

    expect(match.playedSetsCount, 0);
    match.startMatch(DateTime.now());
    expect(match.playedSetsCount, 1);

    for (var set = 1; set <= 3; set++) {
      match.localPoints = 24;
      match.visitPoints = 10;
      match.addPoint(isLocal: true, actionType: PointActionType.attack);
      if (set < 3) expect(match.playedSetsCount, set + 1);
    }

    expect(match.isMatchFinished, isTrue);
    expect(match.localSetsWon, 3);
    expect(match.playedSetsCount, 3);
  });

  testWidgets('LiveClock rebuilds only while enabled', (tester) async {
    var builds = 0;
    Widget clock(bool enabled) => Directionality(
      textDirection: TextDirection.ltr,
      child: LiveClock(
        enabled: enabled,
        builder: (_) {
          builds++;
          return const SizedBox();
        },
      ),
    );

    await tester.pumpWidget(clock(true));
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(builds, 4);

    await tester.pumpWidget(clock(false));
    final afterStop = builds;
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(builds, afterStop);
  });

  testWidgets('Tapping the logo creates a new match', (tester) async {
    final repo = InMemoryMatchRepository();
    await repo.seedSampleData();
    await tester.pumpWidget(SetPointApp(repository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('SetPoint'));
    await tester.pumpAndSettle();
    expect(find.text('Administrar partidos'), findsOneWidget);
    await tester.tap(find.text('Nuevo partido'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo partido'), findsOneWidget);

    await tester.tap(find.text('Local'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('FIME').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Visitante'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tigres UANL').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(repo.matches.length, 3);
    final created = repo.matches.entries.firstWhere(
      (e) => e.key.startsWith('fime_vs_tigres-uanl_'),
    );
    expect(created.value['homeTeamId'], 'fime');
    expect(created.value['awayTeamId'], 'tigres-uanl');
    expect(created.value['stage'], 'Amistoso');
    expect(find.text('Administrar partidos'), findsOneWidget);
    expect(find.text('FIME vs Tigres UANL'), findsOneWidget);

    await tester.tap(find.byTooltip('Borrar partido').first);
    await tester.pumpAndSettle();
    expect(find.text('¿Borrar partido?'), findsOneWidget);
    await tester.tap(find.text('Borrar'));
    await tester.pumpAndSettle();
    expect(repo.matches.length, 2);
  });

  testWidgets('Adding or cancelling a new tournament does not crash', (
    tester,
  ) async {
    final repo = InMemoryMatchRepository();
    await repo.seedSampleData();
    await tester.pumpWidget(SetPointApp(repository: repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SetPoint'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuevo partido'));
    await tester.pumpAndSettle();

    Future<void> openNewTournament() async {
      await tester.tap(find.text('Torneo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('＋ Nuevo torneo…').last);
      await tester.pumpAndSettle();
      expect(find.text('Nuevo torneo'), findsOneWidget);
    }

    await openNewTournament();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await openNewTournament();
    await tester.enterText(find.byType(TextField).last, 'Copa FIME');
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Copa FIME'), findsOneWidget);
  });

  testWidgets('Agenda switches person and remembers the choice', (
    tester,
  ) async {
    Future<void> openAgenda() async {
      await tester.pumpWidget(
        SetPointApp(repository: InMemoryMatchRepository()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Entrenamiento'));
      await tester.pumpAndSettle();
    }

    await openAgenda();
    expect(find.text('Ana López'), findsOneWidget);

    await tester.tap(find.text('Cambiar'));
    await tester.pumpAndSettle();
    expect(find.text('Ver agenda de…'), findsOneWidget);
    await tester.tap(find.text('Carlos Ruiz'));
    await tester.pumpAndSettle();
    expect(find.text('Carlos Ruiz'), findsOneWidget);
    expect(find.text('Opuesto · #7'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await openAgenda();
    expect(find.text('Carlos Ruiz'), findsOneWidget);
  });

  test('Best of 3: third set to 15 and match ends at 2 sets', () {
    final match = MatchModel(
      id: 'm3',
      tournament: TournamentInfo.defaultTournament(),
      stage: 'Final',
      venue: 'Gimnasio',
      startTime: DateTime(2026, 11, 19, 8, 30),
      localTeam: const TeamInfo(
        id: 'a',
        name: 'Local',
        shortName: 'LOC',
        colorValue: 0xFF3449E8,
      ),
      visitTeam: const TeamInfo(
        id: 'b',
        name: 'Visita',
        shortName: 'VIS',
        colorValue: 0xFFE5243B,
      ),
      currentSet: 1,
      localSetsWon: 0,
      visitSetsWon: 0,
      localPoints: 0,
      visitPoints: 0,
      isLocalServing: true,
      isMatchStarted: false,
      isMatchFinished: false,
      setsHistory: [for (var i = 1; i <= 5; i++) SetStatsData(setNumber: i)],
      events: [],
      localLineup: const [],
      visitLineup: const [],
    );
    match.startMatch(DateTime.now());

    match.localPoints = 24;
    match.addPoint(isLocal: true, actionType: PointActionType.attack);
    match.changeBestOf(3);
    expect(match.setsToWin, 2);

    match.visitPoints = 24;
    match.addPoint(isLocal: false, actionType: PointActionType.attack);
    expect(match.currentSet, 3);
    expect(match.targetPointsForCurrentSet, 15);

    match.localPoints = 14;
    match.visitPoints = 13;
    match.addPoint(isLocal: true, actionType: PointActionType.attack);
    expect(match.isMatchFinished, isTrue);
    expect(match.localSetsWon, 2);
    expect(match.playedSetsCount, 3);
  });
}
