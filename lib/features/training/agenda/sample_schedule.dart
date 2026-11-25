import 'schedule_models.dart';

List<Athlete> sampleAthletes() {
  var n = 0;
  ScheduleBlock b(
    int day,
    String start,
    String end,
    ActivityType type,
    String title, [
    String place = '',
  ]) {
    int m(String hhmm) {
      final p = hhmm.split(':');
      return int.parse(p[0]) * 60 + int.parse(p[1]);
    }

    return ScheduleBlock(
      id: 'ej-${n++}',
      weekday: day,
      start: m(start),
      end: m(end),
      type: type,
      title: title,
      place: place,
    );
  }

  List<ScheduleBlock> team() => [
    for (var d = 1; d <= 5; d++)
      b(
        d,
        '16:00',
        '18:00',
        ActivityType.entrenamiento,
        'Entrenamiento de equipo',
        'Gimnasio Cayetano Garza',
      ),
    b(
      6,
      '10:00',
      '12:00',
      ActivityType.partido,
      'Partido de liga',
      'Gimnasio Luis E. Todd',
    ),
    b(7, '09:00', '21:00', ActivityType.descanso, 'Descanso activo'),
  ];

  return [
    Athlete(
      id: 'ana',
      name: 'Ana López',
      role: 'Armadora · #10',
      blocks: [
        ...team(),
        for (final d in [1, 3, 5])
          b(
            d,
            '07:00',
            '08:30',
            ActivityType.fisico,
            'Fuerza y potencia',
            'Gimnasio FIME',
          ),
        b(
          2,
          '09:00',
          '10:00',
          ActivityType.psicologo,
          'Sesión con psicóloga',
          'Centro de Bienestar',
        ),
        for (final d in [1, 2, 3, 4])
          b(d, '11:00', '14:00', ActivityType.estudio, 'Clases', 'FIME'),
        b(
          4,
          '18:15',
          '19:00',
          ActivityType.entrenamiento,
          'Distribución de pases',
          'Cancha 2',
        ),
      ],
    ),
    Athlete(
      id: 'carlos',
      name: 'Carlos Ruiz',
      role: 'Opuesto · #7',
      blocks: [
        ...team(),
        for (final d in [2, 4])
          b(
            d,
            '07:30',
            '09:00',
            ActivityType.fisico,
            'Pliometría y salto',
            'Gimnasio FIME',
          ),
        b(
          3,
          '09:00',
          '10:00',
          ActivityType.fisioterapia,
          'Fisioterapia de hombro',
          'Clínica deportiva',
        ),
        for (final d in [1, 3, 5])
          b(d, '12:00', '15:00', ActivityType.estudio, 'Clases', 'FIME'),
        b(
          1,
          '18:15',
          '19:00',
          ActivityType.entrenamiento,
          'Remate contra bloqueo',
          'Cancha 1',
        ),
      ],
    ),
    Athlete(
      id: 'sofia',
      name: 'Sofía Méndez',
      role: 'Líbero · #4',
      blocks: [
        ...team(),
        b(
          1,
          '08:00',
          '09:00',
          ActivityType.nutricion,
          'Consulta de nutrición',
          'Centro de Bienestar',
        ),
        for (final d in [2, 4])
          b(
            d,
            '07:00',
            '08:00',
            ActivityType.fisico,
            'Agilidad y reacción',
            'Pista de atletismo',
          ),
        b(
          5,
          '09:00',
          '10:00',
          ActivityType.psicologo,
          'Manejo de presión',
          'Centro de Bienestar',
        ),
        for (final d in [2, 3, 4])
          b(d, '10:30', '13:30', ActivityType.estudio, 'Clases', 'FACPYA'),
        b(
          3,
          '18:15',
          '19:00',
          ActivityType.entrenamiento,
          'Recepción en W',
          'Cancha 2',
        ),
      ],
    ),
    Athlete(
      id: 'coach',
      name: 'Laura Garza',
      role: 'Entrenadora',
      blocks: [
        ...team(),
        for (var d = 1; d <= 5; d++)
          b(
            d,
            '14:30',
            '15:30',
            ActivityType.estudio,
            'Planeación de sesión',
            'Oficina',
          ),
        b(
          5,
          '19:00',
          '20:00',
          ActivityType.partido,
          'Análisis de video del rival',
          'Sala audiovisual',
        ),
      ],
    ),
  ];
}
