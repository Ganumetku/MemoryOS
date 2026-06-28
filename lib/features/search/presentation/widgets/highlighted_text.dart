import 'package:flutter/material.dart';

/// Renders a text block with matching query terms highlighted.
class HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;
  final TextStyle highlightStyle;
  final int? maxLines;
  final TextOverflow? overflow;

  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    required this.style,
    required this.highlightStyle,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final queryText = query.trim();
    if (queryText.isEmpty) {
      return Text(text, style: style, maxLines: maxLines, overflow: overflow);
    }

    // Tokenize query words, filtering out filler words
    final cleanWords = queryText
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && !{
              'what', 'did', 'i', 'me', 'tell', 'about', 'show', 'find', 'my', 'the', 'is', 'at', 'on', 'in',
              'a', 'an', 'and', 'or', 'to', 'with', 'for', 'of', 'it', 'that', 'this', 'from', 'by', 'you'
            }.contains(w))
        .toList();

    if (cleanWords.isEmpty) {
      return Text(text, style: style, maxLines: maxLines, overflow: overflow);
    }

    // Sort by length descending to match longer phrases first
    cleanWords.sort((a, b) => b.length.compareTo(a.length));

    final pattern = cleanWords.map((w) => RegExp.escape(w)).join('|');
    final regex = RegExp('($pattern)', caseSensitive: false);

    final spans = <TextSpan>[];
    int start = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, match.start),
          style: style,
        ));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: highlightStyle,
      ));
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: style,
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
