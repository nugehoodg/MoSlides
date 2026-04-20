import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/presentation.dart';
import '../providers/editor_provider.dart';
import '../services/marp_service.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/theme_selector_sheet.dart';
import '../widgets/size_selector_sheet.dart';
import '../widgets/font_size_selector_sheet.dart';
import 'preview_screen.dart';

class EditorScreen extends StatefulWidget {
  final Presentation presentation;
  const EditorScreen({super.key, required this.presentation});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final EditorProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = EditorProvider();
    _provider.init(widget.presentation);
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_provider.hasChanges) return true;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('Do you want to save before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('discard'),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('cancel'),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop('save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == 'save') {
      await _provider.save();
      return true;
    }
    return result == 'discard';
  }

  Future<void> _save() async {
    final updated = await _provider.save();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved ✓'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
      Navigator.of(context).pop(updated);
    }
  }

  void _openPreview() {
    final snap = _provider.snapshotPresentation();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewScreen(
          markdown: snap.content,
          theme: snap.theme,
          size: snap.size,
          fontSize: snap.fontSize,
          title: snap.title,
        ),
      ),
    );
  }

  void _openThemeSelector() {
    showThemeSelectorSheet(
      context,
      current: _provider.theme,
      onSelected: (theme) {
        _provider.setTheme(theme);
        _injectThemeIntoFrontMatter(theme);
      },
    );
  }

  void _injectThemeIntoFrontMatter(String theme) {
    if (_provider.controllers.isEmpty) return;
    final firstCtrl = _provider.controllers.first;
    final text = firstCtrl.text;
    
    if (text.trimLeft().startsWith('---')) {
      final updated = text.replaceAllMapped(
        RegExp(r'^(---\n(?:.*\n)*?)theme:\s*\w+(\n)', multiLine: false),
        (m) => '${m.group(1)}theme: $theme${m.group(2)}',
      );
      if (updated != text) {
        firstCtrl.text = updated;
        return;
      }
      final end = text.indexOf('---', 3);
      if (end != -1) {
        firstCtrl.text = '${text.substring(0, end)}theme: $theme\n${text.substring(end)}';
        return;
      }
    }
    firstCtrl.text = '---\nmarp: true\ntheme: $theme\n---\n\n$text';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final canPop = await _onWillPop();
          if (canPop && context.mounted) Navigator.of(context).pop();
        },
        child: Consumer<EditorProvider>(
          builder: (context, provider, _) => Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
            appBar: _buildAppBar(context, provider),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(child: _buildSlidesList(context, provider)),
                  _buildFilmstrip(context, provider),
                  const EditorToolbar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, EditorProvider provider) {
    final cs = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: cs.surface,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () async {
          final canPop = await _onWillPop();
          if (canPop && context.mounted) Navigator.of(context).pop();
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            provider.presentation.title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 5),
                decoration: BoxDecoration(
                  color: provider.hasChanges ? cs.error : Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                provider.hasChanges ? 'Unsaved' : 'Saved',
                style: TextStyle(
                  fontSize: 11,
                  color: provider.hasChanges
                      ? cs.error
                      : cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                ' · ${provider.controllers.length} slide${provider.controllers.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.format_size_rounded),
          tooltip: 'Change font size',
          onPressed: () {
            showFontSizeSelectorSheet(
              context,
              currentSize: provider.fontSize,
              onSelected: (size) => provider.setFontSize(size),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.aspect_ratio_rounded),
          tooltip: 'Change slide size',
          onPressed: () {
            showSizeSelectorSheet(
              context,
              currentSize: provider.size,
              onSelected: (size) => provider.setSize(size),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.palette_outlined),
          tooltip: 'Change theme',
          onPressed: _openThemeSelector,
        ),
        IconButton(
          icon: const Icon(Icons.slideshow_rounded),
          tooltip: 'Preview',
          onPressed: _openPreview,
        ),
        IconButton(
          icon: Icon(
            Icons.save_rounded,
            color: provider.hasChanges ? cs.primary : cs.onSurfaceVariant,
          ),
          tooltip: 'Save',
          onPressed: provider.hasChanges ? _save : null,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildSlidesList(BuildContext context, EditorProvider provider) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      itemCount: provider.controllers.length + 1,
      onReorder: (oldIndex, newIndex) {
        if (oldIndex == provider.controllers.length || newIndex > provider.controllers.length) {
          return; // Do not reorder the "Add Slide" button
        }
        provider.reorderSlide(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        if (index == provider.controllers.length) {
          return Padding(
            key: const ValueKey('add_slide_button'),
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: FilledButton.tonalIcon(
                onPressed: provider.addNewSlide,
                icon: const Icon(Icons.add),
                label: const Text('Add Slide'),
              ),
            ),
          );
        }
        
        final isActive = provider.activeSlideIndex == index;
        final cs = Theme.of(context).colorScheme;
        
        return Container(
          key: ValueKey(provider.controllers[index]),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? cs.primary : cs.outlineVariant.withAlpha(50),
              width: isActive ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isActive ? 20 : 5),
                blurRadius: isActive ? 12 : 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Header actions: drag handle & delete
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                    child: ReorderableDragStartListener(
                      index: index,
                      child: Icon(Icons.drag_indicator_rounded, size: 20, color: cs.onSurfaceVariant),
                    ),
                  ),
                  if (provider.controllers.length > 1)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 4, 4, 0),
                      child: IconButton(
                        icon: Icon(Icons.close_rounded, size: 18, color: cs.onSurfaceVariant),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        onPressed: () => provider.removeSlide(index),
                        tooltip: 'Remove Slide',
                      ),
                    ),
                ],
              ),
              // Editor Field
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: TextField(
                  controller: provider.controllers[index],
                  focusNode: provider.focusNodes[index],
                  maxLines: null,
                  style: const TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 14,
                    height: 1.65,
                    letterSpacing: 0.2,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Type your slide content here...',
                    hintStyle: TextStyle(
                      color: cs.onSurface.withAlpha(50),
                      fontFamily: 'Courier New',
                      fontSize: 14,
                    ),
                  ),
                  keyboardType: TextInputType.multiline,
                  autocorrect: false,
                  enableSuggestions: false,
                  spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilmstrip(BuildContext context, EditorProvider provider) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withAlpha(80)),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: provider.controllers.length,
        itemBuilder: (context, index) {
          final isActive = provider.activeSlideIndex == index;
          return GestureDetector(
            onTap: () {
              provider.setActiveSlideIndex(index);
              provider.focusNodes[index].requestFocus();
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive ? cs.primary : cs.outlineVariant.withAlpha(50),
                  width: isActive ? 2 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Slide ${index + 1}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                  color: isActive ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
