import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:set_point/core/theme/app_theme.dart';
import 'package:set_point/data/in_memory_match_repository.dart';
import 'package:set_point/main.dart';
import 'package:set_point/models/match_model.dart';

void main() {
  setUpAll(() {
    AppTheme.useGoogleFonts = false;
  });

  testWidgets('SetPoint Sofascore flow, upcoming state, and set timer', (
    WidgetTester tester,
  ) async {
    final repo = InMemoryMatchRepository();

    await tester.pumpWidget(SetPointApp(repository: repo));
    await tester.pumpAndSettle();

    // Empty database state invites user to seed the sample match
    expect(find.text('Aún no hay partidos'), findsOneWidget);
    await tester.tap(find.text('Crear partido de ejemplo'));
    await tester.pumpAndSettle();

    // Verify MatchesScreen renders tournament, teams, and "Por empezar" state
    expect(find.text('Liga Universitaria de Voleibol'), findsOneWidget);
    expect(find.text('Tigres UANL'), findsOneWidget);
    expect(find.text('Borregos MTY'), findsOneWidget);
    expect(find.text('FIME'), findsOneWidget);
    expect(find.text('FACPYA'), findsOneWidget);
    expect(find.text('Por empezar 2'), findsOneWidget);
    expect(find.text('Por empezar'), findsWidgets);

    // Tap the match row to open MatchDetailScreen
    await tester.tap(find.text('Tigres UANL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify tabs and "Partido por empezar" banner are present
    expect(find.text('Detalles'), findsOneWidget);
    expect(find.text('Estadísticas'), findsOneWidget);
    expect(find.text('Alineación'), findsOneWidget);
    expect(find.text('Partido por empezar'), findsOneWidget);
    expect(find.text('Iniciar partido'), findsOneWidget);

    // Start the match and verify it transitions to live with running timer
    await tester.tap(find.text('Iniciar partido'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(repo.matches['partido_demo']!['status'], 'live');
    expect(find.text('1.º set'), findsOneWidget);

    // Score a point for local team and verify repository updated
    expect(repo.matches['partido_demo']!['localPoints'], 0);
    await tester.tap(find.text('Ataque').first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(repo.matches['partido_demo']!['localPoints'], 1);

    // Undo restores the point in repository
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

    // Local wins the set (25-20)
    match.addPoint(isLocal: true, actionType: PointActionType.attack);

    expect(match.localSetsWon, 1);
    expect(match.currentSet, 2);
    expect(match.setsHistory[0].isCompleted, isTrue);
    expect(match.setsHistory[0].durationSeconds, greaterThanOrEqualTo(22 * 60));
  });

  testWidgets('TrainingScreen timer controls do not overflow on narrow screens',
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

    expect(find.text('Descanso entre series'), findsOneWidget);
    expect(find.text('Iniciar'), findsOneWidget);

    await tester.tap(find.text('Iniciar'));
    await tester.pump();
    expect(find.text('Pausar'), findsOneWidget);

    await tester.tap(find.text('Pausar'));
    await tester.pump();
    expect(find.text('Iniciar'), findsOneWidget);
  });
}
