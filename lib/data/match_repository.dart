import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/match_model.dart';

abstract class MatchRepository {
  Stream<List<MatchModel>> watchMatches();
  Stream<MatchModel?> watchMatch(String id);
  Future<void> saveMatchState(MatchModel match);
  Future<void> seedSampleData();
  Future<List<TeamInfo>> loadTeams();
  Future<List<TournamentInfo>> loadTournaments();
  Future<void> createMatch(
    MatchModel match, {
    List<TeamInfo> newTeams = const [],
    TournamentInfo? newTournament,
  });
  Future<void> deleteMatch(String id);
}

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
        ..add(
          a.listen((v) {
            va = v;
            ha = true;
            emit();
          }, onError: controller.addError),
        )
        ..add(
          b.listen((v) {
            vb = v;
            hb = true;
            emit();
          }, onError: controller.addError),
        )
        ..add(
          c.listen((v) {
            vc = v;
            hc = true;
            emit();
          }, onError: controller.addError),
        );
    },
    onCancel: () async {
      for (final s in subs) {
        await s.cancel();
      }
    },
  );
  return controller.stream;
}

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
