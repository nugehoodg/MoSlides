import 'package:flutter/material.dart';

void showFontSizeSelectorSheet(
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
              'Select Font Size',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _SizeTile(
              title: 'Small',
              subtitle: '85% scale',
              isSelected: currentSize == 'Small',
              onTap: () {
                onSelected('Small');
                Navigator.pop(context);
              },
            ),
            _SizeTile(
              title: 'Medium',
              subtitle: '100% standard (Default)',
              isSelected: currentSize == 'Medium',
              onTap: () {
                onSelected('Medium');
                Navigator.pop(context);
              },
            ),
            _SizeTile(
              title: 'Large',
              subtitle: '120% scale',
              isSelected: currentSize == 'Large',
              onTap: () {
                onSelected('Large');
                Navigator.pop(context);
              },
            ),
            _SizeTile(
              title: 'Extra Large',
              subtitle: '150% scaled for maximal readability',
              isSelected: currentSize == 'Extra Large',
              onTap: () {
                onSelected('Extra Large');
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
