import '../models/match_model.dart';

/// Datos del partido de ejemplo. Solo se usan una vez para poblar la base de
/// datos (botón "Crear partido de ejemplo"); a partir de ahí todo se lee y se
/// edita desde Firestore.
class SeedData {
  static TournamentInfo tournament() => const TournamentInfo(
        id: 'liga-universitaria-voleibol',
        name: 'Liga Universitaria de Voleibol',
        category: 'México',
        season: '2026',
      );

  static TeamInfo homeTeam() => const TeamInfo(
        id: 'tigres-uanl',
        name: 'Tigres UANL',
        shortName: 'TIG',
        colorValue: 0xFFF2A900,
        players: [
          TeamPlayer(dorsal: 10, name: 'J. Martínez', role: 'Armador'),
          TeamPlayer(dorsal: 7, name: 'L. Cavazos', role: 'Opuesto'),
          TeamPlayer(dorsal: 14, name: 'C. Mendoza', role: 'Central'),
          TeamPlayer(dorsal: 9, name: 'A. Villarreal', role: 'Banda'),
          TeamPlayer(dorsal: 4, name: 'E. Salinas', role: 'Líbero'),
          TeamPlayer(dorsal: 18, name: 'M. Estrada', role: 'Banda'),
        ],
      );

  static TeamInfo awayTeam() => const TeamInfo(
        id: 'borregos-mty',
        name: 'Borregos MTY',
        shortName: 'BOR',
        colorValue: 0xFF1E6FD9,
        players: [
          TeamPlayer(dorsal: 5, name: 'S. Elizondo', role: 'Armador'),
          TeamPlayer(dorsal: 12, name: 'F. Lozano', role: 'Opuesto'),
          TeamPlayer(dorsal: 15, name: 'G. Cantú', role: 'Central'),
          TeamPlayer(dorsal: 7, name: 'R. Garza', role: 'Banda'),
          TeamPlayer(dorsal: 2, name: 'P. Herrera', role: 'Líbero'),
          TeamPlayer(dorsal: 11, name: 'D. Treviño', role: 'Banda'),
        ],
      );

  static TeamInfo fimeTeam() => const TeamInfo(
        id: 'fime',
        name: 'FIME',
        shortName: 'FIM',
        colorValue: 0xFF007A33,
        players: [
          TeamPlayer(dorsal: 8, name: 'D. Villarreal', role: 'Armador'),
          TeamPlayer(dorsal: 11, name: 'R. Elizondo', role: 'Opuesto'),
          TeamPlayer(dorsal: 15, name: 'M. Garza', role: 'Central'),
          TeamPlayer(dorsal: 4, name: 'A. Rodríguez', role: 'Banda'),
          TeamPlayer(dorsal: 1, name: 'J. Hernández', role: 'Líbero'),
          TeamPlayer(dorsal: 19, name: 'C. Morales', role: 'Banda'),
        ],
      );

  static TeamInfo facpyaTeam() => const TeamInfo(
        id: 'facpya',
        name: 'FACPYA',
        shortName: 'FAC',
        colorValue: 0xFF9E1B32,
        players: [
          TeamPlayer(dorsal: 6, name: 'E. González', role: 'Armador'),
          TeamPlayer(dorsal: 13, name: 'H. Ramírez', role: 'Opuesto'),
          TeamPlayer(dorsal: 16, name: 'O. Castillo', role: 'Central'),
          TeamPlayer(dorsal: 9, name: 'I. Domínguez', role: 'Banda'),
          TeamPlayer(dorsal: 3, name: 'N. Vargas', role: 'Líbero'),
          TeamPlayer(dorsal: 17, name: 'B. Flores', role: 'Banda'),
        ],
      );

  static List<TeamInfo> allTeams() => [
        homeTeam(),
        awayTeam(),
        fimeTeam(),
        facpyaTeam(),
      ];

  static List<PlayerPosition> _lineup(TeamInfo team) => [
        for (var i = 0; i < team.players.length && i < 6; i++)
          PlayerPosition(
            zone: i + 1,
            dorsal: team.players[i].dorsal,
            name: team.players[i].name,
            role: team.players[i].role,
          ),
      ];

  /// Fecha de inicio programada: día 24 a las 8:30 AM (hora local).
  static DateTime scheduledStartTime([int hour = 8, int minute = 30]) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 24, hour, minute);
  }

  static MatchModel match(
    TournamentInfo tournament,
    TeamInfo home,
    TeamInfo away, {
    String id = 'partido_demo',
    String stage = 'Final Conferencia Norte, jornada 14',
    String venue = 'Gimnasio Luis E. Todd, Monterrey',
    DateTime? startTime,
  }) {
    return MatchModel(
      id: id,
      tournament: tournament,
      stage: stage,
      venue: venue,
      startTime: startTime ?? scheduledStartTime(),
      localTeam: home,
      visitTeam: away,
      currentSet: 1,
      localSetsWon: 0,
      visitSetsWon: 0,
      localPoints: 0,
      visitPoints: 0,
      isLocalServing: true,
      isMatchFinished: false,
      recentEvent: '',
      setsHistory: [
        for (var i = 1; i <= 5; i++) SetStatsData(setNumber: i),
      ],
      events: [],
      localLineup: _lineup(home),
      visitLineup: _lineup(away),
    );
  }

  static MatchModel fimeVsFacpyaMatch([TournamentInfo? t]) {
    final tournament = t ?? SeedData.tournament();
    return match(
      tournament,
      fimeTeam(),
      facpyaTeam(),
      id: 'fime_vs_facpya',
      stage: 'Clásico Intrauniversitario, jornada 14',
      venue: 'Gimnasio Cayetano Garza, UANL',
      startTime: scheduledStartTime(10, 30),
    );
  }

  static List<MatchModel> allMatches([TournamentInfo? t]) {
    final tournament = t ?? SeedData.tournament();
    return [
      match(tournament, homeTeam(), awayTeam()),
      fimeVsFacpyaMatch(tournament),
    ];
  }
}
