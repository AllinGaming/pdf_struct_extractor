import 'dart:convert';
import 'dart:io';

import 'package:pdf_struct_extractor/pdf_struct_extractor.dart';

/// Simple example: read a PDF path and print structured JSON.
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run example/main.dart <path-to.pdf>');
    exit(64);
  }
  final result = await PdfStructuredExtractor.extractFromFile(args.first);
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(result));
}
