import 'package:flutter/material.dart';

class MarkdownTextController extends TextEditingController {
  MarkdownTextController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<TextSpan> children = [];
    final textStr = text;

    // A very simple regex-based syntax highlighter for MARP markdown
    // We parse line by line to handle headings, then inline formatting

    // Base styling
    final baseStyle = style ?? const TextStyle();
    final cs = Theme.of(context).colorScheme;

    textStr.splitMapJoin(
      RegExp(r'(?:^|\n)(?:#{1,6}\s+.*|[-*+]\s+.*|>.*|```[\s\S]*?```|.*)', multiLine: true),
      onMatch: (Match m) {
        final line = m[0]!;
        final spanChildren = <TextSpan>[];

        TextStyle? lineStyle;

        if (line.trimLeft().startsWith('```')) {
          lineStyle = baseStyle.copyWith(
            backgroundColor: cs.onSurface.withAlpha(20),
            color: cs.onSurfaceVariant,
            fontFamily: 'Courier New',
          );
        } else if (line.trimLeft().startsWith(RegExp(r'#{1,6}\s'))) {
          // Heading
          final level = line.trimLeft().indexOf(' ');
          lineStyle = baseStyle.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: baseStyle.fontSize! * (1 + 0.1 * (6 - level)),
            color: cs.primary,
          );
        } else if (line.trimLeft().startsWith('>')) {
          // Blockquote
          lineStyle = baseStyle.copyWith(
            fontStyle: FontStyle.italic,
            color: cs.onSurfaceVariant,
          );
        }

        // Inline formatting applied on top of lineStyle
        line.splitMapJoin(
          RegExp(r'(\*\*.*?\*\*|\*.*?\*|`.*?`|\[.*?\]\(.*?\))'),
          onMatch: (Match inlineMatch) {
            final str = inlineMatch[0]!;
            TextStyle? inlineStyle = lineStyle ?? baseStyle;

            if (str.startsWith('**') && str.endsWith('**')) {
              inlineStyle = inlineStyle.copyWith(fontWeight: FontWeight.w900);
            } else if (str.startsWith('*') && str.endsWith('*')) {
              inlineStyle = inlineStyle.copyWith(fontStyle: FontStyle.italic);
            } else if (str.startsWith('`') && str.endsWith('`')) {
              inlineStyle = inlineStyle.copyWith(
                backgroundColor: cs.primary.withAlpha(25),
                color: cs.primary,
                fontFamily: 'Courier New',
              );
            } else if (str.startsWith('[')) {
              inlineStyle = inlineStyle.copyWith(
                color: cs.tertiary,
                decoration: TextDecoration.underline,
              );
            }

            spanChildren.add(TextSpan(text: str, style: inlineStyle));
            return '';
          },
          onNonMatch: (String nonMatch) {
            spanChildren.add(TextSpan(text: nonMatch, style: lineStyle ?? baseStyle));
            return '';
          },
        );

        children.add(TextSpan(children: spanChildren));
        return '';
      },
      onNonMatch: (String nonMatch) {
        children.add(TextSpan(text: nonMatch, style: baseStyle));
        return '';
      },
    );

    return TextSpan(style: baseStyle, children: children);
  }
}
