import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/match_model.dart';
import 'match_repository.dart';
import 'seed_data.dart';

/// Implementación en Cloud Firestore.
///
/// Estructura en tiempo real:
///   tournaments/{id}  → name, category, season
///   teams/{id}        → name, shortName, color ("#RRGGBB"), players[]
///   matches/{id}      → localName, visitName, tournament, stage, venue,
///                       currentSet, localSets, visitSets, localPoints,
///                       visitPoints, isLocalServing, isFinished, recentEvent,
///                       sets[], events[], localLineup[], visitLineup[]
class FirestoreMatchRepository implements MatchRepository {
  final FirebaseFirestore _db;

  FirestoreMatchRepository([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _matches =>
      _db.collection('matches');
  CollectionReference<Map<String, dynamic>> get _teams =>
      _db.collection('teams');
  CollectionReference<Map<String, dynamic>> get _tournaments =>
      _db.collection('tournaments');

  static Map<String, dynamic> _normalize(Map<String, dynamic> data) {
    return data.map(
      (k, v) => MapEntry(k, v is Timestamp ? v.toDate() : v),
    );
  }

  static Stream<Map<String, Map<String, dynamic>>> _byId(
    Query<Map<String, dynamic>> query,
  ) {
    return query.snapshots().map(
          (snap) => {
            for (final d in snap.docs) d.id: _normalize(d.data()),
          },
        );
  }

  @override
  Stream<List<MatchModel>> watchMatches() {
    return combineLatest3(
      _byId(_matches),
      _byId(_teams),
      _byId(_tournaments),
      (m, t, tr) => buildMatches(matches: m, teams: t, tournaments: tr),
    );
  }

  @override
  Stream<MatchModel?> watchMatch(String id) {
    final matchStream = _matches.doc(id).snapshots().map(
          (d) => d.exists
              ? {d.id: _normalize(d.data()!)}
              : <String, Map<String, dynamic>>{},
        );
    return combineLatest3(
      matchStream,
      _byId(_teams),
      _byId(_tournaments),
      (m, t, tr) {
        final list = buildMatches(matches: m, teams: t, tournaments: tr);
        return list.isEmpty ? null : list.first;
      },
    );
  }

  @override
  Future<void> saveMatchState(MatchModel match) {
    return _matches.doc(match.id).set(
      {
        ...match.toStateMap(),
        'localSetsWon': FieldValue.delete(),
        'visitSetsWon': FieldValue.delete(),
        'isMatchFinished': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> seedSampleData() async {
    final batch = _db.batch();
    final tournament = SeedData.tournament();

    batch.set(_tournaments.doc(tournament.id), tournament.toMap());
    for (final team in SeedData.allTeams()) {
      batch.set(_teams.doc(team.id), team.toMap());
    }
    for (final match in SeedData.allMatches(tournament)) {
      batch.set(_matches.doc(match.id), {
        ...match.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
