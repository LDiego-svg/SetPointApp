import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../data/match_repository.dart';
import '../../models/match_model.dart';

/// Mantiene un partido sincronizado con la base de datos en tiempo real.
///
/// Cada acción se aplica primero en local (respuesta instantánea) y después
/// se guarda en Firestore. Los cambios hechos desde otro dispositivo o desde
/// la consola de Firebase llegan por el stream y se aplican sin perder la
/// pila de "deshacer".
///
/// Control de concurrencia ligero (sin transacciones, funciona sin conexión):
/// cada guardado incrementa `rev` y firma con [sessionId]. Mientras hay
/// guardados en curso se ignoran los datos remotos con `rev` menor (son
/// anteriores al estado local). Si llega un `rev` igual al último que
/// guardamos pero firmado por otra sesión, otro dispositivo escribió a la vez:
/// se adopta su versión y se avisa.
///
/// La pila de "deshacer" se conserva en memoria al salir de la pantalla y se
/// recupera al volver, salvo que el partido haya cambiado desde otra sesión.
/// No sobrevive a cerrar la app.
class MatchController extends ChangeNotifier {
  /// Identifica esta ejecución de la app en el campo `updatedBy`.
  static final String sessionId =
      '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';

  /// Pilas de deshacer de los partidos cerrados, con la `rev` que tenían.
  static final Map<String, ({int rev, List<MatchSnapshot> history})>
  _savedUndo = {};

  final MatchRepository repository;
  final String matchId;

  MatchModel? match;
  bool loading = true;
  bool notFound = false;
  Object? error;

  /// Último error al guardar; la UI lo muestra y lo limpia.
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

  /// Recupera la pila conservada solo si nuestro último guardado sigue siendo
  /// el estado actual; si no, deshacer pisaría cambios de otra sesión.
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

  /// Reinicia solo este partido a 0-0 "Por empezar". Devuelve `false` si no
  /// se pudo guardar (el error queda en [saveError]).
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
