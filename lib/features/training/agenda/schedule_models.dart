import 'package:material_ui/material_ui.dart';

/// Tipos de actividad de la agenda. Cada uno tiene etiqueta, icono y color
/// propios (el color es dato de la actividad, como el de un equipo).
enum ActivityType {
  entrenamiento('Entrenamiento', Icons.sports_volleyball_rounded, 0xFF3449E8),
  fisico('Físico', Icons.fitness_center_rounded, 0xFFFF6B00),
  psicologo('Psicólogo', Icons.psychology_rounded, 0xFF7B2CBF),
  nutricion('Nutrición', Icons.restaurant_rounded, 0xFF129A55),
  fisioterapia('Fisioterapia', Icons.healing_rounded, 0xFF0F9D9A),
  partido('Partido', Icons.emoji_events_rounded, 0xFFE5243B),
  estudio('Estudio', Icons.menu_book_rounded, 0xFFF2A900),
  descanso('Descanso', Icons.bedtime_rounded, 0xFF8A90A0);

  final String label;
  final IconData icon;
  final int colorValue;
  const ActivityType(this.label, this.icon, this.colorValue);

  Color get color => Color(colorValue);

  static ActivityType parse(Object? raw) => ActivityType.values.firstWhere(
    (t) => t.name == raw,
    orElse: () => ActivityType.entrenamiento,
  );
}

const weekdayNames = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];
const weekdayLetters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

/// 450 → "07:30".
String formatMinutes(int minutes) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(minutes ~/ 60)}:${two(minutes % 60)}';
}

/// Una actividad de la rutina semanal: se repite cada semana en su día.
class ScheduleBlock {
  final String id;

  /// 1 = lunes … 7 = domingo (como `DateTime.weekday`).
  final int weekday;

  /// Minutos desde medianoche.
  final int start;
  final int end;
  final ActivityType type;
  final String title;
  final String place;

  const ScheduleBlock({
    required this.id,
    required this.weekday,
    required this.start,
    required this.end,
    required this.type,
    required this.title,
    this.place = '',
  });

  int get durationMinutes => end - start;

  ScheduleBlock copyWith({String? id, int? weekday}) => ScheduleBlock(
    id: id ?? this.id,
    weekday: weekday ?? this.weekday,
    start: start,
    end: end,
    type: type,
    title: title,
    place: place,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'weekday': weekday,
    'start': start,
    'end': end,
    'type': type.name,
    'title': title,
    'place': place,
  };

  factory ScheduleBlock.fromMap(Map<String, dynamic> map) {
    int asInt(Object? v, int fallback) =>
        v is num ? v.toInt() : int.tryParse('$v') ?? fallback;
    final type = ActivityType.parse(map['type']);
    final start = asInt(map['start'], 8 * 60).clamp(0, 24 * 60 - 1);
    return ScheduleBlock(
      id: '${map['id'] ?? DateTime.now().microsecondsSinceEpoch}',
      weekday: asInt(map['weekday'], 1).clamp(1, 7),
      start: start,
      end: asInt(map['end'], start + 60).clamp(start + 1, 24 * 60),
      type: type,
      title: (map['title'] as String?)?.trim().isNotEmpty == true
          ? map['title'] as String
          : type.label,
      place: map['place'] as String? ?? '',
    );
  }
}

/// Persona con su rutina semanal (jugador, entrenador, etc.).
class Athlete {
  final String id;
  final String name;
  final String role;
  final List<ScheduleBlock> blocks;

  const Athlete({
    required this.id,
    required this.name,
    this.role = '',
    this.blocks = const [],
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  /// Actividades de un día, ordenadas por hora.
  List<ScheduleBlock> blocksFor(int weekday) =>
      blocks.where((b) => b.weekday == weekday).toList()
        ..sort((a, b) => a.start.compareTo(b.start));

  Athlete copyWith({List<ScheduleBlock>? blocks}) =>
      Athlete(id: id, name: name, role: role, blocks: blocks ?? this.blocks);

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'role': role,
    'blocks': blocks.map((b) => b.toMap()).toList(),
  };

  factory Athlete.fromMap(Map<String, dynamic> map) => Athlete(
    id: '${map['id'] ?? DateTime.now().microsecondsSinceEpoch}',
    name: (map['name'] as String?) ?? 'Persona',
    role: (map['role'] as String?) ?? '',
    blocks: [
      for (final b in (map['blocks'] as List? ?? const []))
        if (b is Map) ScheduleBlock.fromMap(Map<String, dynamic>.from(b)),
    ],
  );
}
