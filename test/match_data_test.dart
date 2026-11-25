import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:set_point/data/in_memory_match_repository.dart';
import 'package:set_point/data/match_repository.dart';
import 'package:set_point/features/matches/match_controller.dart';
import 'package:set_point/models/match_model.dart';

class _SlowRepository extends InMemoryMatchRepository {
  Completer<void>? gate;

  @override
  Future<void> saveMatchState(MatchModel match) async {
    final g = gate;
    if (g != null) await g.future;
    await super.saveMatchState(match);
  }
}

MatchModel _readFromRepo(InMemoryMatchRepository repo, String id) {
  return buildMatches(
    matches: repo.matches,
    teams: repo.teams,
    tournaments: repo.tournaments,
  ).firstWhere((m) => m.id == id);
}

Future<MatchController> _openController(
  InMemoryMatchRepository repo, [
  String id = 'partido_demo',
]) async {
  final c = MatchController(repository: repo, matchId: id);
  await pumpEventQueue();
  expect(c.match, isNotNull);
  return c;
}

void main() {
  test('La pila de deshacer se limita a maxUndoSteps', () async {
    final repo = InMemoryMatchRepository();
    await repo.seedSampleData();
    final m = _readFromRepo(repo, 'partido_demo');

    // Alternar puntos para que ningún set se cierre.
    for (var i = 0; i < MatchModel.maxUndoSteps + 10; i++) {
      if (m.localPoints >= 20 && m.visitPoints >= 20) {
        m.localPoints = 0;
        m.visitPoints = 0;
      }
      m.addPoint(isLocal: i.isEven, actionType: PointActionType.attack);
    }

    var undos = 0;
    while (m.undoLastPoint()) {
      undos++;
    }
    expect(undos, MatchModel.maxUndoSteps);
  });

  test(
    'Deshacer sigue disponible al salir y volver a entrar al partido',
    () async {
      final repo = InMemoryMatchRepository();
      await repo.seedSampleData();
      final c = await _openController(repo);

      c.startMatch();
      c.addPoint(true, PointActionType.attack);
      await pumpEventQueue();
      c.dispose();

      final reopened = MatchController(
        repository: repo,
        matchId: 'partido_demo',
        initial: _readFromRepo(repo, 'partido_demo'),
      );
      await pumpEventQueue();

      expect(reopened.match!.canUndo, isTrue);
      reopened.undo();
      await pumpEventQueue();
      expect(reopened.match!.localPoints, 0);
      expect(reopened.match!.isMatchStarted, isTrue);
      expect(repo.matches['partido_demo']!['localPoints'], 0);
      reopened.dispose();
    },
  );

  test(
    'Al volver no se recupera deshacer si otra sesión cambió el partido',
    () async {
      final repo = InMemoryMatchRepository();
      await repo.seedSampleData();
      final c = await _openController(repo);

      c.addPoint(true, PointActionType.attack);
      await pumpEventQueue();
      c.dispose();

      final remote = _readFromRepo(repo, 'partido_demo')
        ..visitPoints = 1
        ..rev += 1
        ..updatedBy = 'otro-dispositivo';
      await repo.saveMatchState(remote);

      final reopened = await _openController(repo);
      expect(reopened.match!.canUndo, isFalse);
      reopened.dispose();
    },
  );

  test(
    'Al volver no se recupera deshacer tras restaurar los datos de ejemplo',
    () async {
      final repo = InMemoryMatchRepository();
      await repo.seedSampleData();
      final c = await _openController(repo);

      c.addPoint(true, PointActionType.attack);
      await pumpEventQueue();
      c.dispose();

      await repo.seedSampleData();

      final reopened = await _openController(repo);
      expect(reopened.match!.canUndo, isFalse);
      reopened.dispose();
    },
  );

  test('resetGame vuelve a 0-0 sin tocar equipos ni torneo', () async {
    final repo = InMemoryMatchRepository();
    await repo.seedSampleData();
    final m = _readFromRepo(repo, 'partido_demo');

    m.startMatch();
    m.addPoint(isLocal: true, actionType: PointActionType.ace);
    m.addPoint(isLocal: false, actionType: PointActionType.block);
    m.resetGame();

    expect(m.status, MatchStatus.upcoming);
    expect(m.localPoints, 0);
    expect(m.visitPoints, 0);
    expect(m.currentSet, 1);
    expect(m.events, isEmpty);
    expect(m.setStartedAt, isNull);
    expect(m.canUndo, isFalse);
    expect(m.localTeamName, 'Tigres UANL');
    expect(m.tournament.name, 'Liga Universitaria de Voleibol');
    expect(m.localLineup.map((p) => p.zone), [1, 2, 3, 4, 5, 6]);
  });

  test('resetMatch reinicia solo el partido actual', () async {
    final repo = InMemoryMatchRepository();
    await repo.seedSampleData();
    final demo = await _openController(repo);
    final other = await _openController(repo, 'fime_vs_facpya');

    demo.addPoint(true, PointActionType.attack);
    other.addPoint(true, PointActionType.attack);
    await pumpEventQueue();

    expect(await demo.resetMatch(), isTrue);
    await pumpEventQueue();

    expect(repo.matches['partido_demo']!['localPoints'], 0);
    expect(repo.matches['partido_demo']!['status'], 'upcoming');
    expect(repo.matches['fime_vs_facpya']!['localPoints'], 1);

    demo.dispose();
    other.dispose();
  });

  test('Cada guardado incrementa rev y firma la sesión', () async {
    final repo = InMemoryMatchRepository();
    await repo.seedSampleData();
    final c = await _openController(repo);

    c.addPoint(true, PointActionType.attack);
    c.addPoint(false, PointActionType.attack);
    await pumpEventQueue();

    expect(repo.matches['partido_demo']!['rev'], 2);
    expect(
      repo.matches['partido_demo']!['updatedBy'],
      MatchController.sessionId,
    );
    c.dispose();
  });

  test(
    'Se ignoran datos remotos viejos mientras hay un guardado pendiente',
    () async {
      final repo = _SlowRepository();
      await repo.seedSampleData();
      final c = await _openController(repo);

      repo.gate = Completer<void>();
      c.addPoint(true, PointActionType.attack);
      expect(c.match!.localPoints, 1);

      await repo.seedSampleData();
      await pumpEventQueue();
      expect(c.match!.localPoints, 1);

      repo.gate!.complete();
      await pumpEventQueue();
      expect(c.match!.localPoints, 1);
      expect(repo.matches['partido_demo']!['localPoints'], 1);
      c.dispose();
    },
  );

  test(
    'Escritura simultánea de otro dispositivo se adopta y se avisa',
    () async {
      final repo = InMemoryMatchRepository();
      await repo.seedSampleData();
      final c = await _openController(repo);

      c.addPoint(true, PointActionType.attack);
      await pumpEventQueue();
      expect(c.saveError, isNull);

      final remote = _readFromRepo(repo, 'partido_demo')
        ..localPoints = 0
        ..visitPoints = 1
        ..updatedBy = 'otro-dispositivo';
      await repo.saveMatchState(remote);
      await pumpEventQueue();

      expect(c.saveError, contains('Otro dispositivo'));
      expect(c.match!.visitPoints, 1);
      expect(c.match!.localPoints, 0);
      c.dispose();
    },
  );
}
