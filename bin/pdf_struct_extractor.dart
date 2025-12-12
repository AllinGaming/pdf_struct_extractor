import 'dart:convert';
import 'dart:io';

import 'package:pdf_struct_extractor/pdf_struct_extractor.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run pdf_struct_extractor <path-to.pdf> [--max-pages N]');
    exit(64); // usage
  }

  var path = '';
  int? maxPages;

  for (final arg in args) {
    if (arg.startsWith('--max-pages')) {
      final parts = arg.split('=');
      if (parts.length == 2) {
        maxPages = int.tryParse(parts[1]);
      }
      continue;
    }
    if (path.isEmpty) {
      path = arg;
    }
  }

  if (path.isEmpty) {
    stderr.writeln('PDF path is required.');
    exit(64);
  }

  final result = await PdfStructuredExtractor.extractFromFile(path, maxPages: maxPages);
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(result));
}
