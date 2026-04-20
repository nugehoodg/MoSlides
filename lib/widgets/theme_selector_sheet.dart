import 'package:flutter/material.dart';

void showThemeSelectorSheet(
  BuildContext context, {
  required String current,
  required ValueChanged<String> onSelected,
}) {
  showModalBottomSheet(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _ThemeSelectorSheet(current: current, onSelected: onSelected),
  );
}

class _ThemeSelectorSheet extends StatefulWidget {
  final String current;
  final ValueChanged<String> onSelected;
  const _ThemeSelectorSheet({required this.current, required this.onSelected});

  @override
  State<_ThemeSelectorSheet> createState() => _ThemeSelectorSheetState();
}

class _ThemeSelectorSheetState extends State<_ThemeSelectorSheet> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Slide Theme',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select a MARP theme for your presentation',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
            children: [
              _ThemeCard(
                id: 'default',
                name: 'Default',
                description: 'Clean & professional',
                bgColor: const Color(0xFFFFFFFF),
                accentColor: const Color(0xFF1D4ED8),
                textColor: const Color(0xFF1E293B),
                isSelected: _selected == 'default',
                onTap: () => setState(() => _selected = 'default'),
              ),
              _ThemeCard(
                id: 'gaia',
                name: 'Gaia',
                description: 'Dark & elegant',
                bgColor: const Color(0xFF1E1B4B),
                accentColor: const Color(0xFFA5B4FC),
                textColor: const Color(0xFFE0E7FF),
                isSelected: _selected == 'gaia',
                onTap: () => setState(() => _selected = 'gaia'),
              ),
              _ThemeCard(
                id: 'uncover',
                name: 'Uncover',
                description: 'Bold & modern',
                bgColor: const Color(0xFF0F172A),
                accentColor: const Color(0xFF38BDF8),
                textColor: const Color(0xFFF8FAFC),
                isSelected: _selected == 'uncover',
                onTap: () => setState(() => _selected = 'uncover'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () {
                  widget.onSelected(_selected);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Apply Theme'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String id;
  final String name;
  final String description;
  final Color bgColor;
  final Color accentColor;
  final Color textColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.id,
    required this.name,
    required this.description,
    required this.bgColor,
    required this.accentColor,
    required this.textColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isSelected ? 40 : 15),
              blurRadius: isSelected ? 16 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Preview content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 5,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(height: 3, color: textColor.withAlpha(60)),
                  const SizedBox(height: 3),
                  Container(width: 40, height: 3, color: textColor.withAlpha(40)),
                  const Spacer(),
                  Text(
                    description,
                    style: TextStyle(
                      color: textColor.withAlpha(170),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Checkmark
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
