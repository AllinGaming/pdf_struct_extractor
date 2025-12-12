import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pdf_struct_extractor/pdf_struct_extractor.dart';
import 'package:test/test.dart';

void main() {
  test('extracts structured data from sample PDF', () async {
    final bytes = Uint8List.fromList(base64Decode(_samplePdfBase64));
    final file = File('${Directory.systemTemp.path}/sample.pdf');
    await file.writeAsBytes(bytes, flush: true);

    final result =
        await PdfStructuredExtractor.extractFromFile(file.path, maxPages: 1);
    final meta = result['meta'] as Map<String, dynamic>;
    expect(meta['processedPages'], 1);
    expect(meta['pageCount'], greaterThanOrEqualTo(1));

    final pages = result['pages'] as List;
    expect(pages.length, 1);

    final blocks = (pages.first as Map<String, dynamic>)['blocks'] as List;
    expect(blocks, isNotEmpty);
    final hasParagraph = blocks.any((b) {
      final type = (b as Map)['type'];
      return type == 'paragraph' || type == 'list_item';
    });
    expect(hasParagraph, isTrue);
    final hasIndentLevel = blocks
        .where((b) =>
            (b as Map)['type'] == 'paragraph' ||
            // ignore: unnecessary_cast
            (b as Map)['type'] == 'list_item')
        .every(
          (b) => (b as Map).containsKey('indentLevel'),
        );
    expect(hasIndentLevel, isTrue);
  });
}

const _samplePdfBase64 =
    'JVBERi0xLjQKJeLjz9MKMSAwIG9iago8PCAvVHlwZSAvQ2F0YWxvZyAvUGFnZXMgMiAwIFIgPj4KZW5kb2JqCjIgMCBvYmoKPDwgL1R5cGUgL1BhZ2VzIC9Db3VudCAxIC9LaWRzIFszIDAgUl0gPj4KZW5kb2JqCjMgMCBvYmoKPDwgL1R5cGUgL1BhZ2UgL1BhcmVudCAyIDAgUiAvTWVkaWFCb3ggWzAgMCA2MTIgNzkyXSAvUmVzb3VyY2VzIDw8IC9Gb250IDw8IC9GMSA1IDAgUiA+PiA+PiAvQ29udGVudHMgNCAwIFIgPj4KZW5kb2JqCjQgMCBvYmoKPDwgL0xlbmd0aCA0MSA+PgpzdHJlYW0KQlQgL0YxIDI0IFRmIDEwMCA3MDAgVGQgKEhlbGxvIFBERikgVGogRVQKZW5kc3RyZWFtCmVuZG9iago1IDAgb2JqCjw8IC9UeXBlIC9Gb250IC9TdWJ0eXBlIC9UeXBlMSAvQmFzZUZvbnQgL0hlbHZldGljYSA+PgplbmRvYmoKeHJlZgowIDYKMDAwMDAwMDAwMCA2NTUzNSBmIAowMDAwMDAwMDE1IDAwMDAwIG4gCjAwMDAwMDAwNjQgMDAwMDAgbiAKMDAwMDAwMDEyMSAwMDAwMCBuIAowMDAwMDAwMjQ3IDAwMDAwIG4gCjAwMDAwMDAzMzggMDAwMDAgbiAKdHJhaWxlcgo8PCAvU2l6ZSA2IC9Sb290IDEgMCBSID4+CnN0YXJ0eHJlZgo0MDgKJSVFT0YK';
