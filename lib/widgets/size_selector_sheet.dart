import 'package:flutter/material.dart';

void showSizeSelectorSheet(
  BuildContext context, {
  required String currentSize,
  required ValueChanged<String> onSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Slide Size',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _SizeTile(
              title: '1280x720',
              subtitle: '16:9 HD Display',
              isSelected: currentSize == '1280x720',
              onTap: () {
                onSelected('1280x720');
                Navigator.pop(context);
              },
            ),
            _SizeTile(
              title: '1360x768',
              subtitle: '16:9 Standard Native Display (Default)',
              isSelected: currentSize == '1360x768',
              onTap: () {
                onSelected('1360x768');
                Navigator.pop(context);
              },
            ),
            _SizeTile(
              title: '1920x1080',
              subtitle: '16:9 Full HD Presentation',
              isSelected: currentSize == '1920x1080',
              onTap: () {
                onSelected('1920x1080');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}

class _SizeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _SizeTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: isSelected ? 2 : 0,
      color: isSelected ? cs.primaryContainer : cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? cs.primary : Colors.transparent,
          width: 2,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: isSelected ? cs.onPrimaryContainer.withAlpha(200) : cs.onSurfaceVariant),
        ),
        trailing: isSelected ? Icon(Icons.check_circle, color: cs.primary) : null,
        onTap: onTap,
      ),
    );
  }
}
