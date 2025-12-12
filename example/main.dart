import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pdf_struct_extractor/pdf_struct_extractor.dart';

/// Simple example: read a PDF path (or use embedded sample) and print structured JSON.
Future<void> main(List<String> args) async {
  final Uint8List bytes;
  if (args.isEmpty) {
    stderr.writeln('No path provided, using embedded sample PDF.');
    bytes = Uint8List.fromList(base64Decode(_samplePdfBase64));
  } else {
    bytes = await File(args.first).readAsBytes();
  }
  final result = await PdfStructuredExtractor.extractFromBytes(
    bytes,
    sourceName: args.isNotEmpty ? args.first : 'sample.pdf',
  );
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(result));
}

const _samplePdfBase64 =
    'JVBERi0xLjQKJeLjz9MKMSAwIG9iago8PCAvVHlwZSAvQ2F0YWxvZyAvUGFnZXMgMiAwIFIgPj4KZW5kb2JqCjIgMCBvYmoKPDwgL1R5cGUgL1BhZ2VzIC9Db3VudCAxIC9LaWRzIFszIDAgUl0gPj4KZW5kb2JqCjMgMCBvYmoKPDwgL1R5cGUgL1BhZ2UgL1BhcmVudCAyIDAgUiAvTWVkaWFCb3ggWzAgMCA2MTIgNzkyXSAvUmVzb3VyY2VzIDw8IC9Gb250IDw8IC9GMSA1IDAgUiA+PiA+PiAvQ29udGVudHMgNCAwIFIgPj4KZW5kb2JqCjQgMCBvYmoKPDwgL0xlbmd0aCA0MSA+PgpzdHJlYW0KQlQgL0YxIDI0IFRmIDEwMCA3MDAgVGQgKEhlbGxvIFBERikgVGogRVQKZW5kc3RyZWFtCmVuZG9iago1IDAgb2JqCjw8IC9UeXBlIC9Gb250IC9TdWJ0eXBlIC9UeXBlMSAvQmFzZUZvbnQgL0hlbHZldGljYSA+PgplbmRvYmoKeHJlZgowIDYKMDAwMDAwMDAwMCA2NTUzNSBmIAowMDAwMDAwMDE1IDAwMDAwIG4gCjAwMDAwMDAwNjQgMDAwMDAgbiAKMDAwMDAwMDEyMSAwMDAwMCBuIAowMDAwMDAwMjQ3IDAwMDAwIG4gCjAwMDAwMDAzMzggMDAwMDAgbiAKdHJhaWxlcgo8PCAvU2l6ZSA2IC9Sb290IDEgMCBSID4+CnN0YXJ0eHJlZgo0MDgKJSVFT0YK';
