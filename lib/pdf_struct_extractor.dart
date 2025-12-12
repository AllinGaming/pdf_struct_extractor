library pdf_struct_extractor;

import 'dart:typed_data';

import 'src/pdf_struct_extractor_platform.dart';

/// Public API that dispatches to native (pdfrx_engine) or web (pdfrx) implementations.
class PdfStructuredExtractor {
  static final _impl = PdfStructExtractorImpl();

  static Future<Map<String, dynamic>> extractFromFile(String path,
      {int? maxPages, String? pdfiumPath}) {
    return _impl.extractFromFile(path,
        maxPages: maxPages, pdfiumPath: pdfiumPath);
  }

  static Future<Map<String, dynamic>> extractFromBytes(
    Uint8List data, {
    int? maxPages,
    String? sourceName,
    String? pdfiumPath,
  }) {
    return _impl.extractFromBytes(
      data,
      maxPages: maxPages,
      sourceName: sourceName,
      pdfiumPath: pdfiumPath,
    );
  }
}
