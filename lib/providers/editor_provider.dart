import 'package:flutter/material.dart';
import '../models/presentation.dart';
import '../services/storage_service.dart';
import '../utils/markdown_controller.dart';

class EditorProvider extends ChangeNotifier {
  late Presentation _presentation;
  final List<MarkdownTextController> controllers = [];
  final List<FocusNode> focusNodes = [];

  String _theme = 'default';
  String _size = '1360x768';
  String _fontSize = 'Medium';
  bool _hasChanges = false;
  int _activeSlideIndex = 0;

  Presentation get presentation => _presentation;
  String get theme => _theme;
  String get size => _size;
  String get fontSize => _fontSize;
  bool get hasChanges => _hasChanges;
  int get activeSlideIndex => _activeSlideIndex;

  void init(Presentation p) {
    _presentation = p;
    _theme = p.theme;
    _size = p.size;
    _fontSize = p.fontSize;
    _hasChanges = false;
    
    _parseSlidesFromMarkdown(p.content);
  }

  void setActiveSlideIndex(int index) {
    if (index != _activeSlideIndex && index >= 0 && index < controllers.length) {
      _activeSlideIndex = index;
      notifyListeners();
    }
  }

  void _parseSlidesFromMarkdown(String content) {
    controllers.clear();
    for (var fn in focusNodes) {
      fn.dispose();
    }
    focusNodes.clear();

    String body = content;
    String? frontmatter;

    // Extract frontmatter block if present purely to preserve it on the first slide visually or hidden 
    // MARP has `---` frontmatter. We'll attach it to the first slide for simplicity
    if (body.startsWith('---')) {
      final end = body.indexOf('\n---', 3);
      if (end != -1) {
        frontmatter = body.substring(0, end + 4);
        body = body.substring(end + 4);
      }
    }

    // Split slides
    final rawSlides = body.split(RegExp(r'\n---\n'));
    
    if (rawSlides.isEmpty || (rawSlides.length == 1 && rawSlides[0].trim().isEmpty)) {
      _addSlideBlock(frontmatter != null ? '$frontmatter\n\n# New Slide' : '# New Slide');
    } else {
      for (int i = 0; i < rawSlides.length; i++) {
        String slideText = rawSlides[i];
        if (i == 0 && frontmatter != null) {
          slideText = frontmatter + slideText; // Attach frontmatter to the first block
        }
        _addSlideBlock(slideText.trim());
      }
    }
  }

  void _addSlideBlock(String text) {
    final ctrl = MarkdownTextController(text: text);
    ctrl.addListener(_onChanged);
    controllers.add(ctrl);
    
    final fn = FocusNode();
    fn.addListener(() {
      if (fn.hasFocus) {
        int index = focusNodes.indexOf(fn);
        if (index != -1) setActiveSlideIndex(index);
      }
    });
    focusNodes.add(fn);
  }

  void addNewSlide() {
    _addSlideBlock('# Slide ${controllers.length + 1}\n\n');
    _hasChanges = true;
    notifyListeners();
    // Focus the new slide
    Future.delayed(const Duration(milliseconds: 100), () {
      focusNodes.last.requestFocus();
    });
  }

  void removeSlide(int index) {
    if (controllers.length <= 1) return; // Must have at least one slide
    final ctrl = controllers.removeAt(index);
    ctrl.removeListener(_onChanged);
    ctrl.dispose();
    
    final fn = focusNodes.removeAt(index);
    fn.dispose();
    
    if (_activeSlideIndex >= controllers.length) {
      _activeSlideIndex = controllers.length - 1;
    }
    
    _hasChanges = true;
    notifyListeners();
  }

  void reorderSlide(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final ctrl = controllers.removeAt(oldIndex);
    controllers.insert(newIndex, ctrl);
    
    final fn = focusNodes.removeAt(oldIndex);
    focusNodes.insert(newIndex, fn);
    
    if (_activeSlideIndex == oldIndex) {
      _activeSlideIndex = newIndex;
    } else if (oldIndex <= _activeSlideIndex && newIndex >= _activeSlideIndex) {
      _activeSlideIndex -= 1;
    } else if (oldIndex >= _activeSlideIndex && newIndex <= _activeSlideIndex) {
      _activeSlideIndex += 1;
    }
    
    _hasChanges = true;
    notifyListeners();
  }

  String _compileMarkdown() {
    return controllers.map((c) => c.text.trim()).join('\n\n---\n\n');
  }

  void _onChanged() {
    _hasChanges = true;
    notifyListeners();
  }

  void setTheme(String theme) {
    if (_theme == theme) return;
    _theme = theme;
    _hasChanges = true;
    notifyListeners();
  }

  void setSize(String size) {
    if (_size == size) return;
    _size = size;
    _hasChanges = true;
    notifyListeners();
  }

  void setFontSize(String fontSize) {
    if (_fontSize == fontSize) return;
    _fontSize = fontSize;
    _hasChanges = true;
    notifyListeners();
  }

  Future<Presentation> save() async {
    final updated = _presentation.copyWith(
      content: _compileMarkdown(),
      theme: _theme,
      size: _size,
      fontSize: _fontSize,
      lastEdited: DateTime.now(),
    );
    _presentation = updated;
    await StorageService.saveProject(updated);
    _hasChanges = false;
    notifyListeners();
    return updated;
  }

  Presentation snapshotPresentation() => _presentation.copyWith(
        content: _compileMarkdown(),
        theme: _theme,
        size: _size,
        fontSize: _fontSize,
      );

  void insertAtActiveCursor(String text) {
    if (controllers.isEmpty) return;
    final ctrl = controllers[_activeSlideIndex];
    final sel = ctrl.selection;
    if (sel.isValid && sel.start >= 0) {
      final newText = ctrl.text.replaceRange(sel.start, sel.end, text);
      ctrl.value = ctrl.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: sel.start + text.length),
      );
    } else {
      ctrl.text = '${ctrl.text}$text';
      ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
    }
  }

  void wrapSelection(String prefix, String suffix) {
    if (controllers.isEmpty) return;
    final ctrl = controllers[_activeSlideIndex];
    final sel = ctrl.selection;
    
    if (sel.isValid && sel.start >= 0) {
      if (sel.isCollapsed) {
        // Insert empty markers, put cursor inside
        final newText = ctrl.text.replaceRange(sel.start, sel.start, '$prefix$suffix');
        ctrl.value = ctrl.value.copyWith(
          text: newText,
          selection: TextSelection.collapsed(offset: sel.start + prefix.length),
        );
      } else {
        // Wrap selected text
        final selectedText = ctrl.text.substring(sel.start, sel.end);
        final newText = ctrl.text.replaceRange(sel.start, sel.end, '$prefix$selectedText$suffix');
        ctrl.value = ctrl.value.copyWith(
          text: newText,
          selection: TextSelection.collapsed(offset: sel.end + prefix.length + suffix.length),
        );
      }
    } else {
      ctrl.text = '${ctrl.text}$prefix$suffix';
      ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length - suffix.length);
    }
    _onChanged();
  }

  @override
  void dispose() {
    for (var c in controllers) {
      c.removeListener(_onChanged);
      c.dispose();
    }
    for (var f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }
}
