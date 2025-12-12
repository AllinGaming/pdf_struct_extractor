import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:pdfrx_engine/pdfrx_engine.dart';

import 'structuring.dart';

class PdfStructExtractorImpl {
  Future<Map<String, dynamic>> extractFromFile(String path,
      {int? maxPages, String? pdfiumPath}) async {
    await _ensurePdfrxInitialized(pdfiumPath: pdfiumPath);
    final doc = await PdfDocument.openFile(path);
    return _extract(doc, maxPages: maxPages);
  }

  Future<Map<String, dynamic>> extractFromBytes(
    Uint8List data, {
    int? maxPages,
    String? sourceName,
    String? pdfiumPath,
  }) async {
    await _ensurePdfrxInitialized(pdfiumPath: pdfiumPath);
    final doc = await PdfDocument.openData(
      data,
      sourceName: sourceName ?? 'memory',
    );
    return _extract(doc, maxPages: maxPages);
  }
}

Future<void> _ensurePdfrxInitialized({String? pdfiumPath}) async {
  final home = Platform.environment['HOME'];
  final cachedPdfium = pdfiumPath ??
      ((home ?? '').isNotEmpty
          ? '$home/.pdfrx/chromium_2F7520/mac-arm64/lib/libpdfium.dylib'
          : '');
  if (cachedPdfium.isNotEmpty && File(cachedPdfium).existsSync()) {
    Pdfrx.getCacheDirectory ??= () => Directory.systemTemp.path;
    Pdfrx.pdfiumModulePath ??= cachedPdfium;
    await PdfrxEntryFunctions.instance.init();
    return;
  }
  await pdfrxInitialize(); // falls back to downloader if no cached module
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
