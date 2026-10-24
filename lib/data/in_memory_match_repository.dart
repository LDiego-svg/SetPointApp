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
  Future<void> seedSampleData() async {
    final tournament = SeedData.tournament();
    final home = SeedData.homeTeam();
    final away = SeedData.awayTeam();
    final match = SeedData.match(tournament, home, away);
    tournaments[tournament.id] = tournament.toMap();
    teams[home.id] = home.toMap();
    teams[away.id] = away.toMap();
    matches[match.id] = match.toMap();
    _changes.add(null);
  }
}
