import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart';

import 'structuring.dart';

class PdfStructExtractorImpl {
  Future<Map<String, dynamic>> extractFromFile(String path,
      {int? maxPages, String? pdfiumPath}) async {
    throw UnsupportedError(
        'extractFromFile is not supported on web; use extractFromBytes with picked data.');
  }

  Future<Map<String, dynamic>> extractFromBytes(
    Uint8List data, {
    int? maxPages,
    String? sourceName,
    String? pdfiumPath,
  }) async {
    await _ensurePdfrxInitialized();
    final doc = await PdfDocument.openData(
      data,
      sourceName: sourceName ?? 'memory',
    );
    return _extract(doc, maxPages: maxPages);
  }
}

Future<void> _ensurePdfrxInitialized() async {
  // Uses pdfrx Flutter initializer; pdfrx bundles WASM for web targets.
  // Caller must ensure assets are properly configured when building for web.
  await pdfrxFlutterInitialize();
}

Future<Map<String, dynamic>> _extract(
  PdfDocument doc, {
  int? maxPages,
}) async {
  final pagesJson = <Map<String, dynamic>>[];
  final pageSizes = <Map<String, dynamic>>[];
  final limit = maxPages == null
      ? doc.pages.length
      : max<int>(0, min<int>(maxPages, doc.pages.length));
  final toProcess = doc.pages.take(limit);

  for (final page in toProcess) {
    final structured = await page.loadStructuredText(ensureLoaded: true);
    if (structured == null) continue;
    pagesJson.add(
        buildPageJson(structured, page.width, page.height, page.pageNumber));
    pageSizes.add(
        {'page': page.pageNumber, 'width': page.width, 'height': page.height});
  }

  return buildResultJson(
    pageCount: doc.pages.length,
    pages: pagesJson,
    pageSizes: pageSizes,
  );
}
