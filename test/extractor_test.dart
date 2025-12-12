import 'dart:io';

import 'package:pdf_struct_extractor/pdf_struct_extractor.dart';
import 'package:test/test.dart';

void main() {
  test('extracts structured data from sample PDF', () async {
    final path = File('test/data/sample.pdf').path;
    expect(File(path).existsSync(), isTrue);

    final result = await PdfStructuredExtractor.extractFromFile(path, maxPages: 1);
    final meta = result['meta'] as Map<String, dynamic>;
    expect(meta['processedPages'], 1);
    expect(meta['pageCount'], greaterThanOrEqualTo(1));

    final pages = result['pages'] as List;
    expect(pages.length, 1);

    final blocks = (pages.first as Map<String, dynamic>)['blocks'] as List;
    expect(blocks, isNotEmpty);
    final hasParagraph = blocks.any((b) => (b as Map)['type'] == 'paragraph');
    expect(hasParagraph, isTrue);
    final hasIndentLevel = blocks.where((b) => (b as Map)['type'] == 'paragraph').every(
      (b) => (b as Map).containsKey('indentLevel'),
    );
    expect(hasIndentLevel, isTrue);
  });
}
