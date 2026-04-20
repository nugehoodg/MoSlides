import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/presentation.dart';

class StorageService {
  static const String _key = 'moslides_v2_projects';
  static const String _onboardingKey = 'moslides_onboarded';
  static const String _themeKey = 'moslides_theme_mode';

  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_themeKey) ?? 0; // 0: system, 1: light, 2: dark
    return ThemeMode.values[index];
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  static Future<List<Presentation>> loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    final result = <Presentation>[];
    for (final s in list) {
      try {
        result.add(Presentation.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {
        // skip corrupted entries
      }
    }
    result.sort((a, b) => b.lastEdited.compareTo(a.lastEdited));
    return result;
  }

  static Future<void> saveProject(Presentation p) async {
    final prefs = await SharedPreferences.getInstance();
    final projects = await loadProjects();
    final idx = projects.indexWhere((x) => x.id == p.id);
    if (idx >= 0) {
      projects[idx] = p;
    } else {
      projects.insert(0, p);
    }
    await prefs.setStringList(
      _key,
      projects.map((x) => jsonEncode(x.toJson())).toList(),
    );
  }

  static Future<void> deleteProject(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final projects = await loadProjects();
    projects.removeWhere((x) => x.id == id);
    await prefs.setStringList(
      _key,
      projects.map((x) => jsonEncode(x.toJson())).toList(),
    );
  }

  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_onboardingKey) ?? false);
  }

  static Future<void> markOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }
}
