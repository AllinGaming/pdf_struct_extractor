// Shared structuring logic used by both native (pdfrx_engine) and web (pdfrx) builds.

import 'pdf_text_platform.dart';

class Line {
  Line(this.y, this.text, this.height, this.x0, this.x1, this.spans);
  final double y;
  final double height;
  final String text;
  final double x0;
  final double x1;
  final List<Span> spans;
}

class Span {
  Span(this.text, this.x0, this.x1);
  final String text;
  final double x0;
  final double x1;
}

class ListInfo {
  ListInfo(this.cleanedText, this.marker, this.ordered);
  final String cleanedText;
  final String marker;
  final bool ordered;
}

Map<String, dynamic> buildPageJson(
  PdfPageText structured,
  double pageWidth,
  double pageHeight,
  int pageNumber,
) {
  final lines = _fragmentsToLines(structured);
  final paragraphs = _groupLinesIntoParagraphs(lines);
  final blocks = _paragraphsToBlocks(paragraphs, pageWidth);

  return {
    'page': pageNumber,
    'pageWidth': pageWidth,
    'pageHeight': pageHeight,
    'blocks': blocks,
  };
}

Map<String, dynamic> buildResultJson({
  required int pageCount,
  required List<Map<String, dynamic>> pages,
  required List<Map<String, dynamic>> pageSizes,
}) {
  return {
    'meta': {
      'pageCount': pageCount,
      'processedPages': pages.length,
      'pageSizes': pageSizes,
      'unit': 'pt', // PDF points (1/72 inch)
    },
    'pages': pages,
  };
}

List<Map<String, dynamic>> _paragraphsToBlocks(
    List<List<Line>> paragraphs, double pageWidth) {
  final blocks = <Map<String, dynamic>>[];

  for (final para in paragraphs) {
    if (para.isEmpty) continue;
    final firstLine = para.first.text.trim();
    if (_looksLikeHeading(firstLine, para)) {
      blocks.add({'type': 'heading', 'text': firstLine});
      if (para.length > 1) {
        final body = para.skip(1).map((l) => l.text).join(' ').trim();
        if (body.isNotEmpty) {
          final indent = _indentForLines(para);
          blocks.add({
            'type': 'paragraph',
            'text': body,
            'indent': indent,
            'indentLevel': _bucketIndent(indent),
          });
        }
      }
      continue;
    }

    var i = 0;
    while (i < para.length) {
      if (_looksLikeTableRow(para[i], pageWidth)) {
        final rows = <List<String>>[];
        while (i < para.length && _looksLikeTableRow(para[i], pageWidth)) {
          rows.add(para[i]
              .spans
              .map((s) => s.text.trim())
              .where((s) => s.isNotEmpty)
              .toList());
          i++;
        }
        if (rows.length == 1) {
          final rowText = rows.first.join(' ').trim();
          if (rowText.isNotEmpty) {
            blocks.add({
              'type': 'paragraph',
              'text': rowText,
              'indent': para[i - 1].x0,
              'indentLevel': _bucketIndent(para[i - 1].x0),
            });
          }
        } else {
          blocks.add({'type': 'table', 'rows': rows});
        }
        continue;
      }

      final textBuffer = StringBuffer();
      final lineIndent = <double>[];
      while (i < para.length && !_looksLikeTableRow(para[i], pageWidth)) {
        if (textBuffer.isNotEmpty) textBuffer.write(' ');
        textBuffer.write(para[i].text);
        lineIndent.add(para[i].x0);
        i++;
      }
      final text = textBuffer.toString().trim();
      if (text.isNotEmpty) {
        final indent = lineIndent.isEmpty
            ? 0.0
            : lineIndent.reduce((a, b) => a + b) / lineIndent.length;
        final listInfo = _detectList(text, indent);
        if (listInfo != null) {
          blocks.add({
            'type': 'list_item',
            'text': listInfo.cleanedText,
            'indent': indent,
            'indentLevel': _bucketIndent(indent),
            'marker': listInfo.marker,
            'ordered': listInfo.ordered,
          });
        } else {
          blocks.add({
            'type': 'paragraph',
            'text': text,
            'indent': indent,
            'indentLevel': _bucketIndent(indent),
          });
        }
      }
    }
  }

  return blocks;
}

double _indentForLines(List<Line> lines) {
  final xs = lines.map((l) => l.x0).toList();
  xs.sort();
  return xs[xs.length ~/ 2];
}

List<Line> _fragmentsToLines(PdfPageText pageText) {
  if (pageText.fragments.isEmpty) return [];
  final lines = <Line>[];

  StringBuffer buffer = StringBuffer();
  double? currentTop;
  double currentHeight = 0;
  double currentX0 = double.infinity;
  double currentX1 = 0;
  List<Span> currentSpans = [];

  void flush() {
    final text = buffer.toString().trim();
    if (text.isNotEmpty && currentTop != null) {
      lines.add(Line(currentTop!, text, currentHeight, currentX0, currentX1,
          currentSpans));
    }
    buffer = StringBuffer();
    currentTop = null;
    currentHeight = 0;
    currentX0 = double.infinity;
    currentX1 = 0;
    currentSpans = [];
  }

  for (final fragment in pageText.fragments) {
    final raw = pageText.fullText
        .substring(fragment.index, fragment.end)
        .replaceAll('\n', ' ');
    final fragText = raw.trim();
    if (fragText.isEmpty) continue;
    final top = fragment.bounds.top;
    final height = fragment.bounds.height;
    final left = fragment.bounds.left;
    final right = fragment.bounds.right;

    if (currentTop != null) {
      final sameLine = (top - currentTop!).abs() < (height * 0.6);
      if (!sameLine) flush();
    }

    if (currentTop == null) {
      currentTop = top;
      currentHeight = height;
    } else {
      currentHeight = currentHeight > height ? currentHeight : height;
    }

    if (buffer.isNotEmpty) buffer.write(' ');
    buffer.write(fragText);
    currentX0 = currentX0 < left ? currentX0 : left;
    currentX1 = currentX1 > right ? currentX1 : right;
    currentSpans.add(Span(fragText, left, right));
  }

  flush();
  return lines;
}

List<List<Line>> _groupLinesIntoParagraphs(List<Line> lines) {
  if (lines.isEmpty) return [];
  final paragraphs = <List<Line>>[];
  var current = <Line>[lines.first];

  for (var i = 1; i < lines.length; i++) {
    final prev = lines[i - 1];
    final next = lines[i];
    final gap = (next.y - prev.y - prev.height).abs();
    final lineHeight = (prev.height + next.height) / 2;
    final isParagraphBreak =
        gap > lineHeight * 0.8; // tweak threshold if needed
    if (isParagraphBreak) {
      paragraphs.add(current);
      current = [];
    }
    current.add(next);
  }
  paragraphs.add(current);
  return paragraphs;
}

bool _looksLikeHeading(String line, List<Line> para) {
  final trimmed = line.trim();
  if (trimmed.isEmpty) return false;
  final words = trimmed.split(RegExp(r'\s+'));
  if (words.length <= 8 && trimmed == trimmed.toUpperCase()) return true;
  if (RegExp(r'^[0-9]+(\.[0-9]+)*').hasMatch(trimmed) && words.length <= 12) {
    return true;
  }
  final avgHeight =
      para.map((l) => l.height).reduce((a, b) => a + b) / para.length;
  return para.first.height > avgHeight * 1.2;
}

bool _looksLikeTableRow(Line line, double pageWidth) {
  if (line.spans.length < 2) return false;
  final widths = line.spans.map((s) => s.x1 - s.x0).toList();
  final gaps = <double>[];
  for (var i = 0; i < line.spans.length - 1; i++) {
    gaps.add(line.spans[i + 1].x0 - line.spans[i].x1);
  }
  final avgWidth = widths.reduce((a, b) => a + b) / widths.length;
  final avgGap = gaps.reduce((a, b) => a + b) / gaps.length;
  final rowWidth = line.spans.last.x1 - line.spans.first.x0;
  final compactness = rowWidth / pageWidth;
  return (line.spans.length >= 3 && avgGap > pageWidth * 0.02) ||
      (line.spans.length >= 2 &&
          compactness < 0.8 &&
          avgGap > pageWidth * 0.03 &&
          avgWidth < pageWidth * 0.4);
}

ListInfo? _detectList(String text, double indent) {
  final trimmed = text.trimLeft();
  final bulletMatch = RegExp(r'^([•·●\-▪])\s+(.*)$').firstMatch(trimmed);
  if (bulletMatch != null) {
    return ListInfo(bulletMatch.group(2)!.trim(), bulletMatch.group(1)!, false);
  }
  final orderedMatch =
      RegExp(r'^((?:\d+|[a-zA-Z]+)[.)])\s+(.*)$').firstMatch(trimmed);
  if (orderedMatch != null) {
    return ListInfo(
        orderedMatch.group(2)!.trim(), orderedMatch.group(1)!, true);
  }
  if (indent > 70 && trimmed.length < 80) {
    return ListInfo(trimmed, '', false);
  }
  return null;
}

int _bucketIndent(double indent) {
  const bucket = 8.0; // 8pt buckets (~0.11 in)
  return (indent / bucket).round();
}
