import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/match_model.dart';
import 'match_repository.dart';
import 'seed_data.dart';

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
    return data.map((k, v) => MapEntry(k, v is Timestamp ? v.toDate() : v));
  }

  static Stream<Map<String, Map<String, dynamic>>> _byId(
    Query<Map<String, dynamic>> query,
  ) {
    return query.snapshots().map(
      (snap) => {for (final d in snap.docs) d.id: _normalize(d.data())},
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
    final matchStream = _matches
        .doc(id)
        .snapshots()
        .map(
          (d) => d.exists
              ? {d.id: _normalize(d.data()!)}
              : <String, Map<String, dynamic>>{},
        );
    return combineLatest3(matchStream, _byId(_teams), _byId(_tournaments), (
      m,
      t,
      tr,
    ) {
      final list = buildMatches(matches: m, teams: t, tournaments: tr);
      return list.isEmpty ? null : list.first;
    });
  }

  @override
  Future<void> saveMatchState(MatchModel match) {
    return _matches.doc(match.id).set({
      ...match.toStateMap(),
      'localSetsWon': FieldValue.delete(),
      'visitSetsWon': FieldValue.delete(),
      'isMatchFinished': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<List<TeamInfo>> loadTeams() async {
    final snap = await _teams.get();
    return [for (final d in snap.docs) TeamInfo.fromMap(d.id, d.data())]
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<List<TournamentInfo>> loadTournaments() async {
    final snap = await _tournaments.get();
    return [for (final d in snap.docs) TournamentInfo.fromMap(d.id, d.data())]
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<void> createMatch(
    MatchModel match, {
    List<TeamInfo> newTeams = const [],
    TournamentInfo? newTournament,
  }) {
    final batch = _db.batch();
    if (newTournament != null) {
      batch.set(_tournaments.doc(newTournament.id), newTournament.toMap());
    }
    for (final team in newTeams) {
      batch.set(_teams.doc(team.id), team.toMap());
    }
    batch.set(_matches.doc(match.id), {
      ...match.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return batch.commit();
  }

  @override
  Future<void> deleteMatch(String id) => _matches.doc(id).delete();

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
