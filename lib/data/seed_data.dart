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
  static DateTime scheduledStartTime() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 24, 8, 30);
  }

  static MatchModel match(
    TournamentInfo tournament,
    TeamInfo home,
    TeamInfo away, {
    String id = 'partido_demo',
  }) {
    return MatchModel(
      id: id,
      tournament: tournament,
      stage: 'Final Conferencia Norte, jornada 14',
      venue: 'Gimnasio Luis E. Todd, Monterrey',
      startTime: scheduledStartTime(),
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
}
