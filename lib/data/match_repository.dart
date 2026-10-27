import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/match_model.dart';

/// Fuente de datos de partidos. La UI solo conoce esta interfaz, así que la
/// implementación de Firestore puede sustituirse (p. ej. en pruebas).
abstract class MatchRepository {
  /// Todos los partidos con sus equipos y torneo ya resueltos, en tiempo real.
  Stream<List<MatchModel>> watchMatches();

  /// Un partido en tiempo real. Emite `null` si el documento no existe.
  Stream<MatchModel?> watchMatch(String id);

  /// Persiste el estado de juego (marcador, sets, eventos, rotaciones).
  Future<void> saveMatchState(MatchModel match);

  /// Crea el torneo, los dos equipos y el partido de ejemplo.
  Future<void> seedSampleData();
}

/// Combina los mapas crudos de las tres colecciones en modelos.
List<MatchModel> buildMatches({
  required Map<String, Map<String, dynamic>> matches,
  required Map<String, Map<String, dynamic>> teams,
  required Map<String, Map<String, dynamic>> tournaments,
}) {
  final teamInfos = {
    for (final e in teams.entries) e.key: TeamInfo.fromMap(e.key, e.value),
  };
  final tournamentInfos = {
    for (final e in tournaments.entries)
      e.key: TournamentInfo.fromMap(e.key, e.value),
  };
  final list = [
    for (final e in matches.entries)
      MatchModel.fromMap(
        e.key,
        e.value,
        teams: teamInfos,
        tournaments: tournamentInfos,
      ),
  ];
  // En vivo primero, luego por empezar, luego finalizados; dentro de cada grupo por hora.
  int statusOrder(MatchStatus s) {
    switch (s) {
      case MatchStatus.live:
        return 0;
      case MatchStatus.upcoming:
        return 1;
      case MatchStatus.finished:
        return 2;
    }
  }

  list.sort((a, b) {
    final cmp = statusOrder(a.status).compareTo(statusOrder(b.status));
    if (cmp != 0) return cmp;
    return a.startTime.compareTo(b.startTime);
  });
  return list;
}

/// Emite cada vez que cualquiera de las fuentes cambia, una vez que todas
/// emitieron al menos una vez.
Stream<R> combineLatest3<A, B, C, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  R Function(A, B, C) combine,
) {
  late StreamController<R> controller;
  final subs = <StreamSubscription<dynamic>>[];
  A? va;
  B? vb;
  C? vc;
  var ha = false, hb = false, hc = false;

  void emit() {
    if (ha && hb && hc) {
      controller.add(combine(va as A, vb as B, vc as C));
    }
  }

  controller = StreamController<R>(
    onListen: () {
      subs
        ..add(a.listen((v) {
          va = v;
          ha = true;
          emit();
        }, onError: controller.addError))
        ..add(b.listen((v) {
          vb = v;
          hb = true;
          emit();
        }, onError: controller.addError))
        ..add(c.listen((v) {
          vc = v;
          hc = true;
          emit();
        }, onError: controller.addError));
    },
    onCancel: () async {
      for (final s in subs) {
        await s.cancel();
      }
    },
  );
  return controller.stream;
}

/// Hace accesible el repositorio a todo el árbol de widgets.
class RepositoryScope extends InheritedWidget {
  final MatchRepository repository;

  const RepositoryScope({
    super.key,
    required this.repository,
    required super.child,
  });

  static MatchRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RepositoryScope>();
    assert(scope != null, 'RepositoryScope no encontrado en el árbol');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(RepositoryScope oldWidget) =>
      repository != oldWidget.repository;
}
