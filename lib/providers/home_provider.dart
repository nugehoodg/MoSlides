import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/presentation.dart';
import '../services/storage_service.dart';
import '../services/marp_service.dart';

class HomeProvider extends ChangeNotifier {
  List<Presentation> _presentations = [];
  bool _isLoading = true;
  ThemeMode _themeMode = ThemeMode.system;

  List<Presentation> get presentations => _presentations;
  bool get isLoading => _isLoading;
  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _themeMode = await StorageService.getThemeMode();
    _presentations = await StorageService.loadProjects();

    // Seed with default slides on first launch
    if (_presentations.isEmpty && await StorageService.isFirstLaunch()) {
      await StorageService.markOnboarded();
      final sample = Presentation(
        id: const Uuid().v4(),
        title: 'My First Presentation',
        content: MarpService.defaultMarkdown,
        lastEdited: DateTime.now(),
        theme: 'default',
      );
      await StorageService.saveProject(sample);
      _presentations = [sample];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Presentation> createProject(String title) async {
    final p = Presentation(
      id: const Uuid().v4(),
      title: title,
      content: MarpService.defaultMarkdown,
      lastEdited: DateTime.now(),
      theme: 'uncover',
    );
    await StorageService.saveProject(p);
    _presentations.insert(0, p);
    notifyListeners();
    return p;
  }

  Future<void> deleteProject(String id) async {
    await StorageService.deleteProject(id);
    _presentations.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void updateLocal(Presentation updated) {
    final idx = _presentations.indexWhere((p) => p.id == updated.id);
    if (idx >= 0) {
      _presentations[idx] = updated;
      notifyListeners();
    }
  }

  void toggleThemeMode() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    StorageService.saveThemeMode(_themeMode);
    notifyListeners();
  }
}
