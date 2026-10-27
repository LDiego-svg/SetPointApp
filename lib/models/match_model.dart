enum MatchStatus {
  upcoming,
  live,
  finished,
}

extension MatchStatusExtension on MatchStatus {
  String get label {
    switch (this) {
      case MatchStatus.upcoming:
        return 'Por empezar';
      case MatchStatus.live:
        return 'En vivo';
      case MatchStatus.finished:
        return 'Finalizado';
    }
  }

  static MatchStatus parse(
    Object? raw, {
    required bool isStarted,
    required bool isFinished,
  }) {
    if (isFinished) return MatchStatus.finished;
    if (raw is String) {
      final clean = raw.trim().toLowerCase();
      if (clean == 'finished' || clean == 'finalizado') {
        return MatchStatus.finished;
      }
      if (clean == 'live' || clean == 'en_vivo' || clean == 'envivo') {
        return MatchStatus.live;
      }
      if (clean == 'upcoming' ||
          clean == 'not_started' ||
          clean == 'por_empezar') {
        return MatchStatus.upcoming;
      }
    }
    return isStarted ? MatchStatus.live : MatchStatus.upcoming;
  }
}

/// Formatea segundos como `MM:SS` (o `H:MM:SS` si supera una hora).
String formatDurationSeconds(int totalSeconds) {
  final safe = totalSeconds < 0 ? 0 : totalSeconds;
  final hours = safe ~/ 3600;
  final minutes = (safe % 3600) ~/ 60;
  final seconds = safe % 60;
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:$mm:$ss';
  }
  return '$mm:$ss';
}

enum PointActionType {
  attack,
  block,
  ace,
  opponentError,
}

extension PointActionTypeExtension on PointActionType {
  /// Nombre corto para botones y etiquetas.
  String get label {
    switch (this) {
      case PointActionType.attack:
        return 'Ataque';
      case PointActionType.block:
        return 'Bloqueo';
      case PointActionType.ace:
        return 'Ace';
      case PointActionType.opponentError:
        return 'Error rival';
    }
  }

  String get eventDescription {
    switch (this) {
      case PointActionType.attack:
        return 'Ataque diagonal efectivo';
      case PointActionType.block:
        return 'Bloqueo cerrado en red';
      case PointActionType.ace:
        return 'Ace directo de saque';
      case PointActionType.opponentError:
        return 'Error no forzado del rival';
    }
  }

  static PointActionType parse(Object? raw) {
    if (raw is String) {
      for (final t in PointActionType.values) {
        if (t.name == raw) return t;
      }
    }
    return PointActionType.attack;
  }
}

// ---------------------------------------------------------------------------
// Utilidades de lectura tolerante (los datos llegan de Firestore y pueden
// editarse a mano desde la consola, así que nunca confiamos en el tipo exacto).
// ---------------------------------------------------------------------------

int _int(Object? v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

bool _bool(Object? v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is String) return v.toLowerCase() == 'true';
  return fallback;
}

String _str(Object? v, [String fallback = '']) =>
    v == null ? fallback : v.toString();

String _nonEmptyStr(Object? primary, Object? secondary, String fallback) {
  final a = _str(primary).trim();
  if (a.isNotEmpty) return a;
  final b = _str(secondary).trim();
  if (b.isNotEmpty) return b;
  return fallback;
}

List<Map<String, dynamic>> _maps(Object? v) {
  if (v is! List) return const [];
  return v
      .whereType<Map>()
      .map((m) => m.map((k, val) => MapEntry(k.toString(), val)))
      .toList();
}

/// Convierte "#FFB300", "FFB300" o un entero ARGB a un valor ARGB.
int parseColor(Object? raw, int fallback) {
  if (raw is int) return raw;
  if (raw is String) {
    var hex = raw.trim().replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return int.tryParse(hex, radix: 16) ?? fallback;
  }
  return fallback;
}

String colorToHex(int argb) =>
    '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

String _deriveShort(String name, [String? explicit]) {
  final cleanExplicit = (explicit ?? '').trim();
  if (cleanExplicit.isNotEmpty) return cleanExplicit.toUpperCase();
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'EQP';
  final words = trimmed.split(RegExp(r'\s+'));
  if (words.length >= 2 && words.last.length >= 3 && words.last.length <= 4) {
    return words.first.substring(0, 3).toUpperCase();
  }
  return (trimmed.length >= 3 ? trimmed.substring(0, 3) : trimmed)
      .toUpperCase();
}

// ---------------------------------------------------------------------------
// Catálogo: torneos y equipos (colecciones `tournaments` y `teams`).
// ---------------------------------------------------------------------------

class TournamentInfo {
  final String id;
  final String name;
  final String category;
  final String season;

  const TournamentInfo({
    required this.id,
    required this.name,
    this.category = '',
    this.season = '',
  });

  factory TournamentInfo.fromMap(String id, Map<String, dynamic> map) {
    return TournamentInfo(
      id: id,
      name: _str(map['name'], 'Liga Universitaria de Voleibol'),
      category: _str(map['category'], 'México'),
      season: _str(map['season'], '2026'),
    );
  }

  factory TournamentInfo.defaultTournament([String? customName]) =>
      TournamentInfo(
        id: 'liga-universitaria-voleibol',
        name: (customName != null && customName.trim().isNotEmpty)
            ? customName.trim()
            : 'Liga Universitaria de Voleibol',
        category: 'México',
        season: '2026',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'season': season,
      };
}

class TeamPlayer {
  final int dorsal;
  final String name;
  final String role;

  const TeamPlayer({
    required this.dorsal,
    required this.name,
    required this.role,
  });

  factory TeamPlayer.fromMap(Map<String, dynamic> map) => TeamPlayer(
        dorsal: _int(map['dorsal']),
        name: _str(map['name'], 'Jugador'),
        role: _str(map['role']),
      );

  Map<String, dynamic> toMap() => {
        'dorsal': dorsal,
        'name': name,
        'role': role,
      };
}

class TeamInfo {
  final String id;
  final String name;
  final String shortName;
  final int colorValue;
  final List<TeamPlayer> players;

  const TeamInfo({
    required this.id,
    required this.name,
    required this.shortName,
    required this.colorValue,
    this.players = const [],
  });

  factory TeamInfo.fromMap(String id, Map<String, dynamic> map) {
    final name = _str(map['name'], 'Equipo');
    return TeamInfo(
      id: id,
      name: name,
      shortName: _deriveShort(name, _str(map['shortName'])),
      colorValue: parseColor(map['color'], 0xFF3449E8),
      players: _maps(map['players']).map(TeamPlayer.fromMap).toList(),
    );
  }

  TeamInfo copyWith({
    String? id,
    String? name,
    String? shortName,
    int? colorValue,
    List<TeamPlayer>? players,
  }) {
    final nextName = name ?? this.name;
    return TeamInfo(
      id: id ?? this.id,
      name: nextName,
      shortName: shortName ??
          (name != null ? _deriveShort(nextName) : this.shortName),
      colorValue: colorValue ?? this.colorValue,
      players: players ?? this.players,
    );
  }

  TeamPlayer? playerByDorsal(int dorsal) {
    for (final p in players) {
      if (p.dorsal == dorsal) return p;
    }
    return null;
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'shortName': shortName,
        'color': colorToHex(colorValue),
        'players': players.map((p) => p.toMap()).toList(),
      };

  static const List<TeamPlayer> defaultLocalPlayers = [
    TeamPlayer(dorsal: 10, name: 'J. Martínez', role: 'Armador'),
    TeamPlayer(dorsal: 7, name: 'L. Cavazos', role: 'Opuesto'),
    TeamPlayer(dorsal: 14, name: 'C. Mendoza', role: 'Central'),
    TeamPlayer(dorsal: 9, name: 'A. Villarreal', role: 'Banda'),
    TeamPlayer(dorsal: 4, name: 'E. Salinas', role: 'Líbero'),
    TeamPlayer(dorsal: 18, name: 'M. Estrada', role: 'Banda'),
  ];

  static const List<TeamPlayer> defaultVisitPlayers = [
    TeamPlayer(dorsal: 5, name: 'S. Elizondo', role: 'Armador'),
    TeamPlayer(dorsal: 12, name: 'F. Lozano', role: 'Opuesto'),
    TeamPlayer(dorsal: 15, name: 'G. Cantú', role: 'Central'),
    TeamPlayer(dorsal: 7, name: 'R. Garza', role: 'Banda'),
    TeamPlayer(dorsal: 2, name: 'P. Herrera', role: 'Líbero'),
    TeamPlayer(dorsal: 11, name: 'D. Treviño', role: 'Banda'),
  ];
}

// ---------------------------------------------------------------------------
// Estado del partido.
// ---------------------------------------------------------------------------

class PlayerPosition {
  final int zone; // 1 to 6
  final int dorsal;
  final String name;
  final String role;

  const PlayerPosition({
    required this.zone,
    required this.dorsal,
    required this.name,
    required this.role,
  });

  PlayerPosition copyWith({
    int? zone,
    int? dorsal,
    String? name,
    String? role,
  }) {
    return PlayerPosition(
      zone: zone ?? this.zone,
      dorsal: dorsal ?? this.dorsal,
      name: name ?? this.name,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toMap() => {
        'zone': zone,
        'dorsal': dorsal,
        'name': name,
        'role': role,
      };

  factory PlayerPosition.fromMap(Map<String, dynamic> map, TeamInfo team) {
    final dorsal = _int(map['dorsal'], 1);
    final player = team.playerByDorsal(dorsal);
    final explicitName = _str(map['name']).trim();
    final explicitRole = _str(map['role']).trim();
    return PlayerPosition(
      zone: _int(map['zone'], 1),
      dorsal: dorsal,
      name: explicitName.isNotEmpty
          ? explicitName
          : (player?.name ?? 'Jugador #$dorsal'),
      role: explicitRole.isNotEmpty ? explicitRole : (player?.role ?? ''),
    );
  }
}

class MatchEvent {
  final String id;
  final int setNumber;
  final int localPoints;
  final int visitPoints;
  final bool isLocalTeam;
  final String teamName;
  final PointActionType actionType;
  final String description;
  final String playerTag;
  final bool isSetPointWon;

  const MatchEvent({
    required this.id,
    required this.setNumber,
    required this.localPoints,
    required this.visitPoints,
    required this.isLocalTeam,
    required this.teamName,
    required this.actionType,
    required this.description,
    required this.playerTag,
    this.isSetPointWon = false,
  });

  String get scoreLabel => '$localPoints-$visitPoints';

  Map<String, dynamic> toMap() => {
        'id': id,
        'setNumber': setNumber,
        'localPoints': localPoints,
        'visitPoints': visitPoints,
        'isLocalTeam': isLocalTeam,
        'teamName': teamName,
        'actionType': actionType.name,
        'description': description,
        'playerTag': playerTag,
        'isSetPointWon': isSetPointWon,
      };

  factory MatchEvent.fromMap(Map<String, dynamic> map) => MatchEvent(
        id: _str(map['id']),
        setNumber: _int(map['setNumber'], 1),
        localPoints: _int(map['localPoints']),
        visitPoints: _int(map['visitPoints']),
        isLocalTeam: _bool(map['isLocalTeam'], true),
        teamName: _str(map['teamName']),
        actionType: PointActionTypeExtension.parse(map['actionType']),
        description: _str(map['description']),
        playerTag: _str(map['playerTag']),
        isSetPointWon: _bool(map['isSetPointWon']),
      );
}

class RallyPointNode {
  final int setNumber;
  final int localScore;
  final int visitScore;
  final bool isLocalScoring;
  final PointActionType actionType;

  const RallyPointNode({
    required this.setNumber,
    required this.localScore,
    required this.visitScore,
    required this.isLocalScoring,
    required this.actionType,
  });

  Map<String, dynamic> toMap() => {
        'l': localScore,
        'v': visitScore,
        'h': isLocalScoring,
        'a': actionType.name,
      };

  factory RallyPointNode.fromMap(Map<String, dynamic> map, int setNumber) =>
      RallyPointNode(
        setNumber: setNumber,
        localScore: _int(map['l']),
        visitScore: _int(map['v']),
        isLocalScoring: _bool(map['h'], true),
        actionType: PointActionTypeExtension.parse(map['a']),
      );
}

class SetStatsData {
  int setNumber;
  int localScore;
  int visitScore;
  bool isCompleted;

  /// Duración acumulada del set en segundos. Cuando el set termina, guarda el
  /// tiempo total que duró ese set.
  int durationSeconds;

  int localAttacks;
  int visitAttacks;

  int localBlocks;
  int visitBlocks;

  int localAces;
  int visitAces;

  /// Errores no forzados cometidos por cada equipo
  int localUnforcedErrors;
  int visitUnforcedErrors;

  List<RallyPointNode> timeline;

  SetStatsData({
    required this.setNumber,
    this.localScore = 0,
    this.visitScore = 0,
    this.isCompleted = false,
    this.durationSeconds = 0,
    this.localAttacks = 0,
    this.visitAttacks = 0,
    this.localBlocks = 0,
    this.visitBlocks = 0,
    this.localAces = 0,
    this.visitAces = 0,
    this.localUnforcedErrors = 0,
    this.visitUnforcedErrors = 0,
    List<RallyPointNode>? timeline,
  }) : timeline = timeline ?? [];

  int get localTotalPoints => localScore;
  int get visitTotalPoints => visitScore;

  SetStatsData clone() {
    return SetStatsData(
      setNumber: setNumber,
      localScore: localScore,
      visitScore: visitScore,
      isCompleted: isCompleted,
      durationSeconds: durationSeconds,
      localAttacks: localAttacks,
      visitAttacks: visitAttacks,
      localBlocks: localBlocks,
      visitBlocks: visitBlocks,
      localAces: localAces,
      visitAces: visitAces,
      localUnforcedErrors: localUnforcedErrors,
      visitUnforcedErrors: visitUnforcedErrors,
      timeline: List<RallyPointNode>.from(timeline),
    );
  }

  Map<String, dynamic> toMap() => {
        'setNumber': setNumber,
        'localScore': localScore,
        'visitScore': visitScore,
        'isCompleted': isCompleted,
        'durationSeconds': durationSeconds,
        'localAttacks': localAttacks,
        'visitAttacks': visitAttacks,
        'localBlocks': localBlocks,
        'visitBlocks': visitBlocks,
        'localAces': localAces,
        'visitAces': visitAces,
        'localUnforcedErrors': localUnforcedErrors,
        'visitUnforcedErrors': visitUnforcedErrors,
        'timeline': timeline.map((n) => n.toMap()).toList(),
      };

  factory SetStatsData.fromMap(Map<String, dynamic> map, int fallbackNumber) {
    final number = _int(map['setNumber'], fallbackNumber);
    return SetStatsData(
      setNumber: number,
      localScore: _int(map['localScore']),
      visitScore: _int(map['visitScore']),
      isCompleted: _bool(map['isCompleted']),
      durationSeconds: _int(map['durationSeconds']),
      localAttacks: _int(map['localAttacks']),
      visitAttacks: _int(map['visitAttacks']),
      localBlocks: _int(map['localBlocks']),
      visitBlocks: _int(map['visitBlocks']),
      localAces: _int(map['localAces']),
      visitAces: _int(map['visitAces']),
      localUnforcedErrors: _int(map['localUnforcedErrors']),
      visitUnforcedErrors: _int(map['visitUnforcedErrors']),
      timeline: _maps(map['timeline'])
          .map((m) => RallyPointNode.fromMap(m, number))
          .toList(),
    );
  }
}

class MatchSnapshot {
  final int currentSet;
  final int localSetsWon;
  final int visitSetsWon;
  final int localPoints;
  final int visitPoints;
  final bool isLocalServing;
  final bool isMatchStarted;
  final bool isMatchFinished;
  final DateTime? setStartedAt;
  final String recentEvent;
  final List<SetStatsData> setsHistory;
  final List<MatchEvent> events;
  final List<PlayerPosition> localLineup;
  final List<PlayerPosition> visitLineup;

  MatchSnapshot({
    required this.currentSet,
    required this.localSetsWon,
    required this.visitSetsWon,
    required this.localPoints,
    required this.visitPoints,
    required this.isLocalServing,
    required this.isMatchStarted,
    required this.isMatchFinished,
    required this.setStartedAt,
    required this.recentEvent,
    required this.setsHistory,
    required this.events,
    required this.localLineup,
    required this.visitLineup,
  });
}

class MatchModel {
  /// Cuántos eventos se guardan en Firestore (el feed solo muestra los últimos).
  static const int maxStoredEvents = 80;

  final String id;
  TournamentInfo tournament;
  String stage;
  String venue;
  DateTime startTime;
  TeamInfo localTeam;
  TeamInfo visitTeam;

  int currentSet; // 1 to 5
  int localSetsWon;
  int visitSetsWon;
  int localPoints;
  int visitPoints;
  bool isLocalServing;
  bool isMatchStarted;
  bool isMatchFinished;
  DateTime? setStartedAt;
  String recentEvent;

  List<SetStatsData> setsHistory;
  List<MatchEvent> events;
  List<PlayerPosition> localLineup;
  List<PlayerPosition> visitLineup;

  final List<MatchSnapshot> _undoStack = [];

  MatchModel({
    required this.id,
    required this.tournament,
    required this.stage,
    required this.venue,
    required this.startTime,
    required this.localTeam,
    required this.visitTeam,
    required this.currentSet,
    required this.localSetsWon,
    required this.visitSetsWon,
    required this.localPoints,
    required this.visitPoints,
    required this.isLocalServing,
    this.isMatchStarted = false,
    this.isMatchFinished = false,
    this.setStartedAt,
    this.recentEvent = '',
    required this.setsHistory,
    required this.events,
    required this.localLineup,
    required this.visitLineup,
  });

  String get localTeamName => localTeam.name;
  String get localTeamShort => localTeam.shortName;
  String get visitTeamName => visitTeam.name;
  String get visitTeamShort => visitTeam.shortName;

  bool get isUpcoming => !isMatchStarted && !isMatchFinished;
  bool get isLive => isMatchStarted && !isMatchFinished;

  MatchStatus get status => isMatchFinished
      ? MatchStatus.finished
      : (isMatchStarted ? MatchStatus.live : MatchStatus.upcoming);

  bool get isTimerRunning => isLive && setStartedAt != null;

  /// Segundos transcurridos de un set específico (1..5).
  int setElapsedSeconds(int setNumber, [DateTime? now]) {
    if (setNumber < 1 || setNumber > setsHistory.length) return 0;
    final s = setsHistory[setNumber - 1];
    if (s.isCompleted || !isLive || setNumber != currentSet || setStartedAt == null) {
      return s.durationSeconds;
    }
    final delta = (now ?? DateTime.now()).difference(setStartedAt!).inSeconds;
    return s.durationSeconds + (delta > 0 ? delta : 0);
  }

  /// Segundos transcurridos del set en juego (o del último set si ya terminó).
  int get currentSetElapsedSeconds => setElapsedSeconds(currentSet);

  /// Duración acumulada de todos los sets jugados o en juego.
  int get totalMatchElapsedSeconds {
    final now = DateTime.now();
    var total = 0;
    for (var i = 1; i <= setsHistory.length; i++) {
      total += setElapsedSeconds(i, now);
    }
    return total;
  }

  bool get canUndo => _undoStack.isNotEmpty;

  int get targetPointsForCurrentSet => currentSet == 5 ? 15 : 25;

  SetStatsData get currentSetData => setsHistory[currentSet - 1];

  // -------------------------------------------------------------------------
  // Serialización
  // -------------------------------------------------------------------------

  /// Campos completos del documento `matches/{id}`. Incluye tanto referencias
  /// a colecciones (`tournamentId`, `homeTeamId`, `awayTeamId`) como campos
  /// directos (`localName`, `visitName`, `tournament`, etc.) para que puedas
  /// editarlos directamente en el documento del partido desde Firebase Console.
  Map<String, dynamic> toMap() => {
        'tournamentId': tournament.id,
        'tournament': tournament.name,
        'homeTeamId': localTeam.id,
        'awayTeamId': visitTeam.id,
        'localName': localTeam.name,
        'visitName': visitTeam.name,
        'localShort': localTeam.shortName,
        'visitShort': visitTeam.shortName,
        'localColor': colorToHex(localTeam.colorValue),
        'visitColor': colorToHex(visitTeam.colorValue),
        'stage': stage,
        'venue': venue,
        'startTime': startTime,
        ...toStateMap(),
      };

  /// Estado que cambia durante el juego o desde la edición rápida.
  Map<String, dynamic> toStateMap() => {
        'localName': localTeam.name,
        'visitName': visitTeam.name,
        'localShort': localTeam.shortName,
        'visitShort': visitTeam.shortName,
        'localColor': colorToHex(localTeam.colorValue),
        'visitColor': colorToHex(visitTeam.colorValue),
        'tournament': tournament.name,
        'stage': stage,
        'venue': venue,
        'startTime': startTime,
        'currentSet': currentSet,
        'localSets': localSetsWon,
        'visitSets': visitSetsWon,
        'localPoints': localPoints,
        'visitPoints': visitPoints,
        'isLocalServing': isLocalServing,
        'status': status.name,
        'isStarted': isMatchStarted,
        'isFinished': isMatchFinished,
        'setStartedAt': setStartedAt,
        'recentEvent': recentEvent,
        'sets': setsHistory.map((s) => s.toMap()).toList(),
        'events':
            events.take(maxStoredEvents).map((e) => e.toMap()).toList(),
        'localLineup': localLineup.map((p) => p.toMap()).toList(),
        'visitLineup': visitLineup.map((p) => p.toMap()).toList(),
      };

  static List<PlayerPosition> _defaultLineupFor(TeamInfo team) => [
        for (var i = 0; i < team.players.length && i < 6; i++)
          PlayerPosition(
            zone: i + 1,
            dorsal: team.players[i].dorsal,
            name: team.players[i].name,
            role: team.players[i].role,
          ),
      ];

  static (String?, String?) _parseTeamsFromDocId(String id) {
    final match = RegExp(
      r'^([a-zA-Z0-9_-]+?)[_-]vs[_-]([a-zA-Z0-9_-]+)$',
      caseSensitive: false,
    ).firstMatch(id.trim());
    if (match == null) return (null, null);
    final rawHome = match.group(1)!.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    final rawAway = match.group(2)!.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    if (rawHome.isEmpty || rawAway.isEmpty) return (null, null);
    return (rawHome.toUpperCase(), rawAway.toUpperCase());
  }

  factory MatchModel.fromMap(
    String id,
    Map<String, dynamic> map, {
    required Map<String, TeamInfo> teams,
    required Map<String, TournamentInfo> tournaments,
  }) {
    final (idHome, idAway) = _parseTeamsFromDocId(id);
    final rawHomeId = _nonEmptyStr(map['homeTeamId'], map['localTeamId'], '');
    final rawAwayId = _nonEmptyStr(map['awayTeamId'], map['visitTeamId'], '');
    final homeId = rawHomeId.isNotEmpty
        ? rawHomeId
        : (idHome != null ? idHome.toLowerCase() : 'tigres-uanl');
    final awayId = rawAwayId.isNotEmpty
        ? rawAwayId
        : (idAway != null ? idAway.toLowerCase() : 'borregos-mty');
    final tournamentId = _nonEmptyStr(
      map['tournamentId'],
      null,
      'liga-universitaria-voleibol',
    );

    final baseHome = teams[homeId] ??
        TeamInfo(
          id: homeId,
          name: rawHomeId.isNotEmpty
              ? rawHomeId.toUpperCase()
              : (idHome ?? 'Tigres UANL'),
          shortName: _deriveShort(
            rawHomeId.isNotEmpty
                ? rawHomeId.toUpperCase()
                : (idHome ?? 'Tigres UANL'),
          ),
          colorValue: homeId == 'fime' ? 0xFF007A33 : 0xFFF2A900,
          players: TeamInfo.defaultLocalPlayers,
        );
    final baseAway = teams[awayId] ??
        TeamInfo(
          id: awayId,
          name: rawAwayId.isNotEmpty
              ? rawAwayId.toUpperCase()
              : (idAway ?? 'Borregos MTY'),
          shortName: _deriveShort(
            rawAwayId.isNotEmpty
                ? rawAwayId.toUpperCase()
                : (idAway ?? 'Borregos MTY'),
          ),
          colorValue: awayId == 'facpya' ? 0xFF9E1B32 : 0xFF1E6FD9,
          players: TeamInfo.defaultVisitPlayers,
        );

    final homeName = _nonEmptyStr(
      map['localName'],
      map['localTeamName'] ?? map['home'] ?? map['local'],
      baseHome.name,
    );
    final awayName = _nonEmptyStr(
      map['visitName'],
      map['visitTeamName'] ?? map['away'] ?? map['visit'],
      baseAway.name,
    );

    final home = baseHome.copyWith(
      name: homeName,
      shortName: _deriveShort(
        homeName,
        _nonEmptyStr(map['localShort'], map['localTeamShort'], ''),
      ),
      colorValue: parseColor(map['localColor'], baseHome.colorValue),
      players: baseHome.players.isNotEmpty
          ? baseHome.players
          : TeamInfo.defaultLocalPlayers,
    );

    final away = baseAway.copyWith(
      name: awayName,
      shortName: _deriveShort(
        awayName,
        _nonEmptyStr(map['visitShort'], map['visitTeamShort'], ''),
      ),
      colorValue: parseColor(map['visitColor'], baseAway.colorValue),
      players: baseAway.players.isNotEmpty
          ? baseAway.players
          : TeamInfo.defaultVisitPlayers,
    );

    final baseTournament = tournaments[tournamentId];
    final customTournamentName =
        _nonEmptyStr(map['tournament'], map['tournamentName'], '');
    final tournament = customTournamentName.isNotEmpty
        ? TournamentInfo(
            id: baseTournament?.id ?? tournamentId,
            name: customTournamentName,
            category: baseTournament?.category ?? 'México',
            season: baseTournament?.season ?? '2026',
          )
        : (baseTournament ?? TournamentInfo.defaultTournament());

    final currentSet = _int(map['currentSet'], 1).clamp(1, 5);
    final localPoints = _int(map['localPoints']);
    final visitPoints = _int(map['visitPoints']);

    // Soportar tanto `localSets` / `visitSets` como `localSetsWon` / `visitSetsWon`.
    final localSetsWon = map.containsKey('localSets')
        ? _int(map['localSets'], _int(map['localSetsWon']))
        : _int(map['localSetsWon']);
    final visitSetsWon = map.containsKey('visitSets')
        ? _int(map['visitSets'], _int(map['visitSetsWon']))
        : _int(map['visitSetsWon']);

    final rawEvents = _maps(map['events']);
    final hasScoreActivity = localSetsWon > 0 ||
        visitSetsWon > 0 ||
        localPoints > 0 ||
        visitPoints > 0 ||
        rawEvents.isNotEmpty;

    final rawFinished = map.containsKey('isFinished')
        ? (_bool(map['isFinished']) || _bool(map['isMatchFinished']))
        : _bool(map['isMatchFinished']);

    final rawStarted = map.containsKey('isStarted')
        ? _bool(map['isStarted'])
        : (map.containsKey('isMatchStarted')
            ? _bool(map['isMatchStarted'])
            : hasScoreActivity);

    final parsedStatus = MatchStatusExtension.parse(
      map['status'],
      isStarted: rawStarted || hasScoreActivity,
      isFinished: rawFinished,
    );

    final isMatchFinished = parsedStatus == MatchStatus.finished;
    final isMatchStarted =
        parsedStatus == MatchStatus.live || parsedStatus == MatchStatus.finished;

    final rawSets = _maps(map['sets']);
    final sets = <SetStatsData>[
      for (var i = 0; i < 5; i++)
        i < rawSets.length
            ? SetStatsData.fromMap(rawSets[i], i + 1)
            : SetStatsData(setNumber: i + 1),
    ];

    // Mantener el parcial del set actual sincronizado con localPoints/visitPoints
    // por si se modificaron directamente desde Firebase Console.
    if (!isMatchFinished && currentSet >= 1 && currentSet <= 5) {
      final activeSet = sets[currentSet - 1];
      activeSet.localScore = localPoints;
      activeSet.visitScore = visitPoints;
    }

    final parsedLocalLineup = _maps(map['localLineup'])
        .map((m) => PlayerPosition.fromMap(m, home))
        .toList();
    final parsedVisitLineup = _maps(map['visitLineup'])
        .map((m) => PlayerPosition.fromMap(m, away))
        .toList();

    final start = map['startTime'];
    final now = DateTime.now();

    final rawSetStartedAt = map['setStartedAt'];
    DateTime? setStartedAt;
    if (rawSetStartedAt is DateTime) {
      setStartedAt = rawSetStartedAt;
    } else if (rawSetStartedAt is String) {
      setStartedAt = DateTime.tryParse(rawSetStartedAt);
    }

    return MatchModel(
      id: id,
      tournament: tournament,
      stage: _nonEmptyStr(
        map['stage'],
        null,
        'Final Conferencia Norte · Jornada 14',
      ),
      venue: _nonEmptyStr(
        map['venue'],
        null,
        'Gimnasio Luis E. Todd, Monterrey',
      ),
      startTime:
          start is DateTime ? start : DateTime(now.year, now.month, 24, 8, 30),
      localTeam: home,
      visitTeam: away,
      currentSet: currentSet,
      localSetsWon: localSetsWon,
      visitSetsWon: visitSetsWon,
      localPoints: localPoints,
      visitPoints: visitPoints,
      isLocalServing: _bool(map['isLocalServing'], true),
      isMatchStarted: isMatchStarted,
      isMatchFinished: isMatchFinished,
      setStartedAt: isMatchFinished ? null : setStartedAt,
      recentEvent: _str(map['recentEvent']),
      setsHistory: sets,
      events: rawEvents.map(MatchEvent.fromMap).toList(),
      localLineup: parsedLocalLineup.length == 6
          ? parsedLocalLineup
          : _defaultLineupFor(home),
      visitLineup: parsedVisitLineup.length == 6
          ? parsedVisitLineup
          : _defaultLineupFor(away),
    );
  }

  /// Aplica datos que llegan de la base de datos conservando la pila de
  /// deshacer local.
  void applyRemote(MatchModel other) {
    tournament = other.tournament;
    stage = other.stage;
    venue = other.venue;
    startTime = other.startTime;
    localTeam = other.localTeam;
    visitTeam = other.visitTeam;
    currentSet = other.currentSet;
    localSetsWon = other.localSetsWon;
    visitSetsWon = other.visitSetsWon;
    localPoints = other.localPoints;
    visitPoints = other.visitPoints;
    isLocalServing = other.isLocalServing;
    isMatchStarted = other.isMatchStarted;
    isMatchFinished = other.isMatchFinished;
    setStartedAt = other.setStartedAt;
    recentEvent = other.recentEvent;
    setsHistory = other.setsHistory;
    events = other.events;
    localLineup = other.localLineup;
    visitLineup = other.visitLineup;
  }

  // -------------------------------------------------------------------------
  // Lógica de juego
  // -------------------------------------------------------------------------

  void _saveSnapshot() {
    _undoStack.add(
      MatchSnapshot(
        currentSet: currentSet,
        localSetsWon: localSetsWon,
        visitSetsWon: visitSetsWon,
        localPoints: localPoints,
        visitPoints: visitPoints,
        isLocalServing: isLocalServing,
        isMatchStarted: isMatchStarted,
        isMatchFinished: isMatchFinished,
        setStartedAt: setStartedAt,
        recentEvent: recentEvent,
        setsHistory: setsHistory.map((s) => s.clone()).toList(),
        events: List<MatchEvent>.from(events),
        localLineup: List<PlayerPosition>.from(localLineup),
        visitLineup: List<PlayerPosition>.from(visitLineup),
      ),
    );
  }

  /// Inicia el partido desde el estado "Por empezar" y arranca el reloj del 1.º set.
  void startMatch([DateTime? now]) {
    if (isMatchStarted || isMatchFinished) return;
    _saveSnapshot();
    final t = now ?? DateTime.now();
    isMatchStarted = true;
    setStartedAt = t;
    if (recentEvent.isEmpty) {
      recentEvent = 'Comienza el $currentSet.º set';
    }
  }

  /// Pausa o reanuda el reloj del set en curso.
  void toggleTimer([DateTime? now]) {
    if (!isLive) return;
    final t = now ?? DateTime.now();
    final activeSet = setsHistory[currentSet - 1];
    if (setStartedAt != null) {
      activeSet.durationSeconds = setElapsedSeconds(currentSet, t);
      setStartedAt = null;
    } else {
      setStartedAt = t;
    }
  }

  bool undoLastPoint() {
    if (_undoStack.isEmpty) return false;
    final prevSet = currentSet;
    final prevWasFinished = isMatchFinished;
    final liveDurationBeforeUndo =
        (!isMatchFinished && currentSet >= 1 && currentSet <= setsHistory.length)
            ? setsHistory[currentSet - 1].durationSeconds
            : 0;
    final liveStartedAtBeforeUndo = setStartedAt;

    final snap = _undoStack.removeLast();
    currentSet = snap.currentSet;
    localSetsWon = snap.localSetsWon;
    visitSetsWon = snap.visitSetsWon;
    localPoints = snap.localPoints;
    visitPoints = snap.visitPoints;
    isLocalServing = snap.isLocalServing;
    isMatchStarted = snap.isMatchStarted;
    isMatchFinished = snap.isMatchFinished;
    recentEvent = snap.recentEvent;
    setsHistory = snap.setsHistory;
    events = snap.events;
    localLineup = snap.localLineup;
    visitLineup = snap.visitLineup;

    if (!isMatchStarted || isMatchFinished) {
      setStartedAt = null;
    } else if (snap.currentSet != prevSet || prevWasFinished) {
      // Si se deshizo el punto que cerró el set o el partido, reanudamos el
      // reloj del set previo a partir del tiempo que llevaba acumulado.
      setStartedAt = DateTime.now();
    } else {
      // Si se deshizo un punto dentro del mismo set, el reloj del set sigue
      // corriendo sin retroceder.
      setsHistory[currentSet - 1].durationSeconds = liveDurationBeforeUndo;
      setStartedAt = liveStartedAtBeforeUndo ?? snap.setStartedAt;
    }
    return true;
  }

  /// Rotación reglamentaria en sentido horario:
  /// Zona 2 -> Zona 1 (Saque), Z1 -> Z6, Z6 -> Z5, Z5 -> Z4, Z4 -> Z3, Z3 -> Z2.
  void rotateTeamLineup(bool isLocal) {
    final current = isLocal ? localLineup : visitLineup;
    final Map<int, PlayerPosition> byZone = {
      for (final p in current) p.zone: p,
    };
    if (!List.generate(6, (i) => i + 1).every(byZone.containsKey)) return;
    final List<PlayerPosition> rotated = [
      byZone[2]!.copyWith(zone: 1),
      byZone[3]!.copyWith(zone: 2),
      byZone[4]!.copyWith(zone: 3),
      byZone[5]!.copyWith(zone: 4),
      byZone[6]!.copyWith(zone: 5),
      byZone[1]!.copyWith(zone: 6),
    ];
    if (isLocal) {
      localLineup = rotated;
    } else {
      visitLineup = rotated;
    }
  }

  void addPoint({
    required bool isLocal,
    required PointActionType actionType,
  }) {
    if (isMatchFinished) return;

    _saveSnapshot();

    final now = DateTime.now();
    if (!isMatchStarted) {
      isMatchStarted = true;
    }
    setStartedAt ??= now;

    // Si el equipo que anota no tenía el saque (Side-out), recupera saque y rota
    if (isLocal != isLocalServing) {
      isLocalServing = isLocal;
      rotateTeamLineup(isLocal);
    }

    if (isLocal) {
      localPoints++;
    } else {
      visitPoints++;
    }

    final setStats = setsHistory[currentSet - 1];
    setStats.localScore = localPoints;
    setStats.visitScore = visitPoints;

    switch (actionType) {
      case PointActionType.attack:
        if (isLocal) {
          setStats.localAttacks++;
        } else {
          setStats.visitAttacks++;
        }
        break;
      case PointActionType.block:
        if (isLocal) {
          setStats.localBlocks++;
        } else {
          setStats.visitBlocks++;
        }
        break;
      case PointActionType.ace:
        if (isLocal) {
          setStats.localAces++;
        } else {
          setStats.visitAces++;
        }
        break;
      case PointActionType.opponentError:
        if (isLocal) {
          setStats.visitUnforcedErrors++;
        } else {
          setStats.localUnforcedErrors++;
        }
        break;
    }

    setStats.timeline.add(
      RallyPointNode(
        setNumber: currentSet,
        localScore: localPoints,
        visitScore: visitPoints,
        isLocalScoring: isLocal,
        actionType: actionType,
      ),
    );

    final activeLineup = isLocal ? localLineup : visitLineup;
    PlayerPosition? featuredPlayer;
    if (activeLineup.isNotEmpty) {
      featuredPlayer = activeLineup.firstWhere(
        (p) => actionType == PointActionType.ace
            ? p.zone == 1
            : (actionType == PointActionType.block
                ? p.zone == 3
                : p.zone == 4),
        orElse: () => activeLineup.first,
      );
    }

    final int target = targetPointsForCurrentSet;
    final int diff = (localPoints - visitPoints).abs();
    final bool setWon =
        (localPoints >= target || visitPoints >= target) && diff >= 2;

    final int scoredSetNumber = currentSet;
    final int snapshotLocalPts = localPoints;
    final int snapshotVisitPts = visitPoints;
    final String scoringTeam = isLocal ? localTeamName : visitTeamName;
    final int elapsedThisSet = setElapsedSeconds(currentSet, now);
    final String setTimeLabel = formatDurationSeconds(elapsedThisSet);
    final String desc = setWon
        ? 'Gana el set $scoringTeam en $setTimeLabel (${actionType.eventDescription})'
        : actionType.eventDescription;

    recentEvent = '$snapshotLocalPts-$snapshotVisitPts · $desc ($scoringTeam)';

    events.insert(
      0,
      MatchEvent(
        id: '${now.microsecondsSinceEpoch}',
        setNumber: scoredSetNumber,
        localPoints: snapshotLocalPts,
        visitPoints: snapshotVisitPts,
        isLocalTeam: isLocal,
        teamName: scoringTeam,
        actionType: actionType,
        description: desc,
        playerTag: featuredPlayer == null
            ? ''
            : '#${featuredPlayer.dorsal} ${featuredPlayer.name}',
        isSetPointWon: setWon,
      ),
    );

    if (setWon) {
      // El reloj del set se detiene cuando un equipo gana el set y guarda lo que duró.
      setStats.durationSeconds = elapsedThisSet;
      setStats.isCompleted = true;
      if (isLocal) {
        localSetsWon++;
      } else {
        visitSetsWon++;
      }

      if (localSetsWon == 3 || visitSetsWon == 3 || currentSet == 5) {
        isMatchFinished = true;
        setStartedAt = null;
      } else {
        currentSet++;
        localPoints = 0;
        visitPoints = 0;
        setsHistory[currentSet - 1].durationSeconds = 0;
        setStartedAt = now;
      }
    }
  }

  /// Devuelve las estadísticas acumuladas ('ALL') o de un set específico (1..5)
  SetStatsData getStatsForFilter(int setFilterIndex) {
    if (setFilterIndex >= 1 && setFilterIndex <= 5) {
      return setsHistory[setFilterIndex - 1];
    }

    int totalLocalScore = 0;
    int totalVisitScore = 0;
    int totalDuration = 0;
    int totalLocalAttacks = 0;
    int totalVisitAttacks = 0;
    int totalLocalBlocks = 0;
    int totalVisitBlocks = 0;
    int totalLocalAces = 0;
    int totalVisitAces = 0;
    int totalLocalErrors = 0;
    int totalVisitErrors = 0;
    final List<RallyPointNode> allTimeline = [];
    final now = DateTime.now();

    for (final s in setsHistory) {
      totalLocalScore += s.localScore;
      totalVisitScore += s.visitScore;
      totalDuration += setElapsedSeconds(s.setNumber, now);
      totalLocalAttacks += s.localAttacks;
      totalVisitAttacks += s.visitAttacks;
      totalLocalBlocks += s.localBlocks;
      totalVisitBlocks += s.visitBlocks;
      totalLocalAces += s.localAces;
      totalVisitAces += s.visitAces;
      totalLocalErrors += s.localUnforcedErrors;
      totalVisitErrors += s.visitUnforcedErrors;
      allTimeline.addAll(s.timeline);
    }

    return SetStatsData(
      setNumber: 0,
      localScore: totalLocalScore,
      visitScore: totalVisitScore,
      isCompleted: isMatchFinished,
      durationSeconds: totalDuration,
      localAttacks: totalLocalAttacks,
      visitAttacks: totalVisitAttacks,
      localBlocks: totalLocalBlocks,
      visitBlocks: totalVisitBlocks,
      localAces: totalLocalAces,
      visitAces: totalVisitAces,
      localUnforcedErrors: totalLocalErrors,
      visitUnforcedErrors: totalVisitErrors,
      timeline: allTimeline,
    );
  }
}
