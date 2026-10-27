import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/match_repository.dart';
import '../../models/match_model.dart';

/// Mantiene un partido sincronizado con la base de datos en tiempo real.
///
/// Cada acción se aplica primero en local (respuesta instantánea) y después
/// se guarda en Firestore. Los cambios hechos desde otro dispositivo o desde
/// la consola de Firebase llegan por el stream y se aplican sin perder la
/// pila de "deshacer".
class MatchController extends ChangeNotifier {
  final MatchRepository repository;
  final String matchId;

  MatchModel? match;
  bool loading = true;
  bool notFound = false;
  Object? error;

  /// Último error al guardar; la UI lo muestra y lo limpia.
  String? saveError;

  StreamSubscription<MatchModel?>? _sub;
  Timer? _clockTicker;

  MatchController({
    required this.repository,
    required this.matchId,
    MatchModel? initial,
  }) : match = initial {
    loading = initial == null;
    _clockTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final m = match;
      if (m != null && m.isTimerRunning) {
        notifyListeners();
      }
    });
    _sub = repository.watchMatch(matchId).listen(
      (remote) {
        loading = false;
        error = null;
        if (remote == null) {
          notFound = true;
        } else if (match == null) {
          match = remote;
          notFound = false;
        } else {
          match!.applyRemote(remote);
          notFound = false;
        }
        notifyListeners();
      },
      onError: (Object e) {
        loading = false;
        error = e;
        notifyListeners();
      },
    );
  }

  Future<void> _persist() async {
    final m = match;
    if (m == null) return;
    try {
      await repository.saveMatchState(m);
    } catch (e) {
      saveError = 'No se pudo guardar en la base de datos: $e';
      notifyListeners();
    }
  }

  void startMatch() {
    final m = match;
    if (m == null || !m.isUpcoming) return;
    m.startMatch();
    notifyListeners();
    _persist();
  }

  void toggleTimer() {
    final m = match;
    if (m == null || !m.isLive) return;
    m.toggleTimer();
    notifyListeners();
    _persist();
  }

  void addPoint(bool isLocal, PointActionType action) {
    final m = match;
    if (m == null || m.isMatchFinished) return;
    m.addPoint(isLocal: isLocal, actionType: action);
    notifyListeners();
    _persist();
  }

  void undo() {
    final m = match;
    if (m == null || !m.undoLastPoint()) return;
    notifyListeners();
    _persist();
  }

  void rotate(bool isLocal) {
    final m = match;
    if (m == null) return;
    m.rotateTeamLineup(isLocal);
    notifyListeners();
    _persist();
  }

  Future<void> updateMatchDetails({
    required String localName,
    required String visitName,
    required String tournamentName,
    required String stage,
    required String venue,
    required int currentSet,
    required int localSets,
    required int visitSets,
    required int localPoints,
    required int visitPoints,
    required MatchStatus status,
    required String recentEvent,
  }) async {
    final m = match;
    if (m == null) return;
    m.localTeam = m.localTeam.copyWith(name: localName.trim());
    m.visitTeam = m.visitTeam.copyWith(name: visitName.trim());
    m.tournament = TournamentInfo(
      id: m.tournament.id,
      name: tournamentName.trim(),
      category: m.tournament.category,
      season: m.tournament.season,
    );
    m.stage = stage.trim();
    m.venue = venue.trim();
    m.currentSet = currentSet.clamp(1, 5);
    m.localSetsWon = localSets.clamp(0, 3);
    m.visitSetsWon = visitSets.clamp(0, 3);
    m.localPoints = localPoints.clamp(0, 99);
    m.visitPoints = visitPoints.clamp(0, 99);

    switch (status) {
      case MatchStatus.upcoming:
        m.isMatchStarted = false;
        m.isMatchFinished = false;
        m.setStartedAt = null;
        break;
      case MatchStatus.live:
        m.isMatchStarted = true;
        m.isMatchFinished = false;
        m.setStartedAt ??= DateTime.now();
        break;
      case MatchStatus.finished:
        if (m.setStartedAt != null) {
          m.setsHistory[m.currentSet - 1].durationSeconds =
              m.setElapsedSeconds(m.currentSet);
        }
        m.isMatchStarted = true;
        m.isMatchFinished = true;
        m.setStartedAt = null;
        break;
    }

    m.recentEvent = recentEvent.trim();
    m.setsHistory[m.currentSet - 1].localScore = m.localPoints;
    m.setsHistory[m.currentSet - 1].visitScore = m.visitPoints;
    notifyListeners();
    await _persist();
  }

  Future<void> resetMatch() async {
    try {
      await repository.seedSampleData();
    } catch (e) {
      saveError = 'No se pudo reiniciar el partido: $e';
      notifyListeners();
    }
  }

  void clearSaveError() => saveError = null;

  @override
  void dispose() {
    _clockTicker?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}
