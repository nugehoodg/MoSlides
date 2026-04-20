import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/editor_provider.dart';

class EditorToolbar extends StatelessWidget {
  const EditorToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(80),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              _btn(
                context,
                icon: Icons.title_rounded,
                label: 'H1',
                tooltip: 'Insert heading',
                onTap: () => _insert(context, '\n# '),
              ),
              _btn(
                context,
                icon: Icons.format_list_bulleted_rounded,
                label: 'List',
                tooltip: 'Insert list item',
                onTap: () => _insert(context, '\n- '),
              ),
              _btn(
                context,
                icon: Icons.code_rounded,
                label: 'Code',
                tooltip: 'Insert code block',
                onTap: () => _insert(context, '\n```\n\n```\n'),
              ),
              _btn(
                context,
                icon: Icons.image_outlined,
                label: 'Image',
                tooltip: 'Insert physical image',
                onTap: () => _pickImage(context),
              ),
              _btn(
                context,
                icon: Icons.format_bold_rounded,
                label: 'Bold',
                tooltip: 'Bold',
                onTap: () => _wrap(context, '**', '**'),
                iconOnly: true,
              ),
              _btn(
                context,
                icon: Icons.format_italic_rounded,
                label: 'Italic',
                tooltip: 'Italic',
                onTap: () => _wrap(context, '*', '*'),
                iconOnly: true,
              ),
              _btn(
                context,
                icon: Icons.format_align_left_rounded,
                label: 'Left',
                tooltip: 'Align Left',
                onTap: () => _wrap(context, '\n::: left\n', '\n:::\n'),
                iconOnly: true,
              ),
              _btn(
                context,
                icon: Icons.format_align_center_rounded,
                label: 'Center',
                tooltip: 'Align Center',
                onTap: () => _wrap(context, '\n::: center\n', '\n:::\n'),
                iconOnly: true,
              ),
              _btn(
                context,
                icon: Icons.format_align_right_rounded,
                label: 'Right',
                tooltip: 'Align Right',
                onTap: () => _wrap(context, '\n::: right\n', '\n:::\n'),
                iconOnly: true,
              ),
              _btn(
                context,
                icon: Icons.format_quote_rounded,
                label: 'Quote',
                tooltip: 'Blockquote',
                onTap: () => _wrap(context, '\n> ', ''),
                iconOnly: true,
              ),
              _btn(
                context,
                icon: Icons.horizontal_rule_rounded,
                label: 'HR',
                tooltip: 'Horizontal Rule',
                onTap: () => _insert(context, '\n---\n'),
                iconOnly: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _insert(BuildContext context, String text) {
    context.read<EditorProvider>().insertAtActiveCursor(text);
  }

  void _wrap(BuildContext context, String prefix, String suffix) {
    context.read<EditorProvider>().wrapSelection(prefix, suffix);
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (xFile == null) return; // User canceled
    if (!context.mounted) return;

    // Show alignment layout dialog before inserting
    final alignment = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Image Layout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.align_horizontal_left_rounded),
              title: const Text('Left Split (Text wraps right)'),
              onTap: () => Navigator.pop(ctx, 'left'),
            ),
            ListTile(
              leading: const Icon(Icons.align_horizontal_center_rounded),
              title: const Text('Center Block'),
              onTap: () => Navigator.pop(ctx, 'center'),
            ),
            ListTile(
              leading: const Icon(Icons.align_horizontal_right_rounded),
              title: const Text('Right Split (Text wraps left)'),
              onTap: () => Navigator.pop(ctx, 'right'),
            ),
          ],
        ),
      ),
    );

    if (alignment == null) return; // User canceled dialog
    if (!context.mounted) return;

    // Save file locally to ensure persistence across sessions
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${xFile.name}';
    final savedFile = File('${appDir.path}/$fileName');
    
    // Copy the picked file to app directory
    await File(xFile.path).copy(savedFile.path);

    // Format the syntax for injection based on MARP standards mapping to local file URI
    String markdownSnippet;
    final uri = 'file://${savedFile.path}';
    
    switch (alignment) {
      case 'left':
        markdownSnippet = '\n![bg left:40%]($uri)\n';
        break;
      case 'right':
        markdownSnippet = '\n![bg right:40%]($uri)\n';
        break;
      case 'center':
      default:
        markdownSnippet = '\n<p align="center"><img src="$uri" height="300"></p>\n';
        break;
    }

    _insert(context, markdownSnippet);
  }

  Widget _btn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String tooltip,
    required VoidCallback onTap,
    bool iconOnly = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: iconOnly
              ? Icon(icon, size: 20, color: cs.onSurfaceVariant)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: cs.primary),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
