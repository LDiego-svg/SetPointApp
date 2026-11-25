import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../data/match_repository.dart';
import '../../models/match_model.dart';

class MatchController extends ChangeNotifier {
  static final String sessionId =
      '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';

  // Conserva el historial de deshacer en memoria al salir de la pantalla.
  static final Map<String, ({int rev, List<MatchSnapshot> history})>
  _savedUndo = {};

  final MatchRepository repository;
  final String matchId;

  MatchModel? match;
  bool loading = true;
  bool notFound = false;
  Object? error;
  String? saveError;

  StreamSubscription<MatchModel?>? _sub;
  int _pendingSaves = 0;
  int? _lastSavedRev;

  MatchController({
    required this.repository,
    required this.matchId,
    MatchModel? initial,
  }) : match = initial {
    loading = initial == null;
    if (initial != null) _restoreUndo(initial);
    _sub = repository
        .watchMatch(matchId)
        .listen(
          (remote) {
            loading = false;
            error = null;
            if (remote == null) {
              notFound = true;
            } else if (match == null) {
              match = remote;
              _restoreUndo(remote);
              notFound = false;
            } else {
              final local = match!;
              if (_pendingSaves > 0 && remote.rev < local.rev) {
                // Dato anterior a un guardado local que aún no termina.
                return;
              }
              if (remote.rev == _lastSavedRev &&
                  remote.updatedBy.isNotEmpty &&
                  remote.updatedBy != sessionId) {
                saveError =
                    'Otro dispositivo modificó el partido al mismo '
                    'tiempo. Se cargó su marcador; revisa el último punto.';
                _lastSavedRev = null;
              }
              local.applyRemote(remote);
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

  // Solo restaura si nadie más modificó el partido desde otra sesión.
  void _restoreUndo(MatchModel m) {
    final saved = _savedUndo.remove(matchId);
    if (saved != null && saved.rev == m.rev && m.updatedBy == sessionId) {
      m.restoreUndoHistory(saved.history);
    }
  }

  void _saveUndo() {
    final m = match;
    if (m != null && m.canUndo) {
      _savedUndo[matchId] = (rev: m.rev, history: m.undoHistory);
    }
  }

  Future<bool> _persist({
    String errorPrefix = 'No se pudo guardar en la base de datos',
  }) async {
    final m = match;
    if (m == null) return false;
    m.rev++;
    m.updatedBy = sessionId;
    _lastSavedRev = m.rev;
    _pendingSaves++;
    try {
      await repository.saveMatchState(m);
      return true;
    } catch (e) {
      saveError = '$errorPrefix: $e';
      notifyListeners();
      return false;
    } finally {
      _pendingSaves--;
    }
  }

  void startMatch() {
    final m = match;
    if (m == null || !m.isUpcoming) return;
    m.startMatch();
    notifyListeners();
    _persist();
  }

  void changeBestOf(int value) {
    final m = match;
    if (m == null || m.bestOf == value) return;
    m.changeBestOf(value);
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
          m.setsHistory[m.currentSet - 1].durationSeconds = m.setElapsedSeconds(
            m.currentSet,
          );
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

  Future<bool> resetMatch() async {
    final m = match;
    if (m == null) return false;
    m.resetGame();
    notifyListeners();
    return _persist(errorPrefix: 'No se pudo reiniciar el partido');
  }

  void clearSaveError() => saveError = null;

  @override
  void dispose() {
    _saveUndo();
    _sub?.cancel();
    super.dispose();
  }
}
