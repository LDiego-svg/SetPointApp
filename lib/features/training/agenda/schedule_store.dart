import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sample_schedule.dart';
import 'schedule_models.dart';

class ScheduleStore {
  static const _athletesKey = 'training.schedule.athletes.v1';
  static const _selectedKey = 'training.schedule.selected';

  const ScheduleStore();

  Future<List<Athlete>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_athletesKey);
      if (raw == null) return sampleAthletes();
      return [
        for (final a in jsonDecode(raw) as List)
          if (a is Map) Athlete.fromMap(Map<String, dynamic>.from(a)),
      ];
    } catch (e) {
      debugPrint('No se pudo leer la agenda: $e');
      return sampleAthletes();
    }
  }

  Future<void> save(List<Athlete> athletes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _athletesKey,
        jsonEncode([for (final a in athletes) a.toMap()]),
      );
    } catch (e) {
      debugPrint('No se pudo guardar la agenda: $e');
    }
  }

  Future<String?> loadSelected() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_selectedKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSelected(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedKey, id);
    } catch (_) {}
  }
}
