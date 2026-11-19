import 'dart:async';

import '../models/match_model.dart';
import 'match_repository.dart';
import 'seed_data.dart';

/// Repositorio en memoria con el mismo formato de documentos que Firestore.
/// Se usa en pruebas y como referencia del esquema.
class InMemoryMatchRepository implements MatchRepository {
  final Map<String, Map<String, dynamic>> matches = {};
  final Map<String, Map<String, dynamic>> teams = {};
  final Map<String, Map<String, dynamic>> tournaments = {};

  final _changes = StreamController<void>.broadcast();

  List<MatchModel> _build() =>
      buildMatches(matches: matches, teams: teams, tournaments: tournaments);

  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    yield* _changes.stream.map((_) => read());
  }

  @override
  Stream<List<MatchModel>> watchMatches() => _watch(_build);

  @override
  Stream<MatchModel?> watchMatch(String id) => _watch(() {
    for (final m in _build()) {
      if (m.id == id) return m;
    }
    return null;
  });

  @override
  Future<void> saveMatchState(MatchModel match) async {
    final doc = matches[match.id];
    if (doc == null) throw StateError('El partido ${match.id} no existe');
    doc.addAll(match.toStateMap());
    _changes.add(null);
  }

  @override
  Future<List<TeamInfo>> loadTeams() async =>
      [for (final e in teams.entries) TeamInfo.fromMap(e.key, e.value)]
        ..sort((a, b) => a.name.compareTo(b.name));

  @override
  Future<List<TournamentInfo>> loadTournaments() async => [
    for (final e in tournaments.entries) TournamentInfo.fromMap(e.key, e.value),
  ]..sort((a, b) => a.name.compareTo(b.name));

  @override
  Future<void> createMatch(
    MatchModel match, {
    List<TeamInfo> newTeams = const [],
    TournamentInfo? newTournament,
  }) async {
    if (newTournament != null) {
      tournaments[newTournament.id] = newTournament.toMap();
    }
    for (final team in newTeams) {
      teams[team.id] = team.toMap();
    }
    matches[match.id] = match.toMap();
    _changes.add(null);
  }

  @override
  Future<void> deleteMatch(String id) async {
    matches.remove(id);
    _changes.add(null);
  }

  @override
  Future<void> seedSampleData() async {
    final tournament = SeedData.tournament();
    tournaments[tournament.id] = tournament.toMap();
    for (final team in SeedData.allTeams()) {
      teams[team.id] = team.toMap();
    }
    for (final match in SeedData.allMatches(tournament)) {
      matches[match.id] = match.toMap();
    }
    _changes.add(null);
  }
}
