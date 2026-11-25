import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrainingProgressStore {
  static const _completedKey = 'training.completedDrillIds';

  const TrainingProgressStore();

  Future<Set<String>> loadCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_completedKey) ?? const []).toSet();
    } catch (e) {
      debugPrint('No se pudo leer el progreso de entrenamiento: $e');
      return {};
    }
  }

  Future<void> saveCompleted(Set<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_completedKey, ids.toList()..sort());
    } catch (e) {
      debugPrint('No se pudo guardar el progreso de entrenamiento: $e');
    }
  }
}
