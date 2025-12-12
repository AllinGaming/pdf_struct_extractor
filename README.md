# pdf_struct_extractor
[![pub package](https://img.shields.io/pub/v/pdf_struct_extractor?label=pub)](https://pub.dev/packages/pdf_struct_extractor)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![build](https://github.com/AllinGaming/pdf_struct_extractor/actions/workflows/ci.yml/badge.svg)](https://github.com/AllinGaming/pdf_struct_extractor/actions/workflows/ci.yml)
[![style](https://img.shields.io/badge/style-flutter__lints-blue)](https://pub.dev/packages/flutter_lints)

Extract structured text from PDFs (headings, paragraphs, list items, simple tables) into a JSON-friendly Map using `pdfrx_engine` (PDFium, pure Dart).

## Install
```yaml
dependencies:
  pdf_struct_extractor: ^0.1.0
```

## Quick start
```dart
import 'dart:convert';
import 'package:pdf_struct_extractor/pdf_struct_extractor.dart';

Future<void> main() async {
  final data = await PdfStructuredExtractor.extractFromFile('path/to.pdf');
  print(const JsonEncoder.withIndent('  ').convert(data));
}
```

CLI:
```
flutter pub run pdf_struct_extractor <path-to.pdf> [--max-pages=N]
```

Example:
```
# uses embedded sample if no path is provided
dart run example/main.dart > output.json
# or provide your own
dart run example/main.dart path/to/your.pdf > output.json
```

## JSON shape
- `meta`: `pageCount`, `processedPages`, `pageSizes` (`page`, `width`, `height`, unit `pt` = 1/72"), `unit`.
- `pages`: list of pages with `page`, `pageWidth`, `pageHeight`, `blocks`.
- `blocks` (per page):
  - Paragraph: `{ "type": "paragraph", "text": "...", "indent": <double>, "indentLevel": <int> }`
  - List item: `{ "type": "list_item", "text": "...", "indent": <double>, "indentLevel": <int>, "marker": "•"|"1."|..., "ordered": bool }`
  - Heading: `{ "type": "heading", "text": "..." }`
  - Table: `{ "type": "table", "rows": [ [ "cell1", "cell2", ... ], ... ] }`

## Indent meaning
- `indent`: left offset from page origin (top-left) in PDF points.
- `indentLevel`: `indent` bucketed into 8pt steps for easier nesting detection.
- Usage ideas:
  - Treat similar indents (±5–10 pt) as the same level.
  - Increased indent vs. previous block implies nested list/quote.
  - Normalize by page width if needed (`indent / pageWidth`).

## Heuristics
- Headings: short lines in ALL CAPS, numbered (`1.`, `1.2`), or taller than surrounding lines.
- Paragraph breaks: vertical gap vs. line height.
- Tables: lines with multiple spans and large X-gaps; consecutive rows are grouped.
- Lists: bullet/number markers detected; otherwise indent-only items with big left offset are marked as list items.

## Tweaking
- Paragraph break: `_groupLinesIntoParagraphs`.
- Headings: `_looksLikeHeading`.
- Tables: `_looksLikeTableRow`.
- List detection and indent bucketing: `_detectList`, `_bucketIndent`.

## Notes
- Native: uses `pdfrx_engine` (FFI to PDFium). On first run it downloads PDFium unless a cached module exists under `~/.pdfrx/.../libpdfium.*`. Provide `pdfiumPath` to skip download.
- Web: uses `pdfrx` (WASM). Ensure pdfrx web assets are bundled per pdfrx docs when building Flutter web.
- Output is plain Dart `Map`/`List` suitable for JSON encoding. Extend `_paragraphsToBlocks` if you need line/span coordinates.
- Platforms: Flutter mobile/desktop/web (with WASM configured); Dart VM/CLI also works when Flutter SDK is available.
- Flutter web note: pdfrx requires WASM assets (PDFium) to be bundled/configured per pdfrx documentation for web builds. This package does not bundle them for you.

## Publish checklist
- Update `repository`, `homepage`, `issue_tracker` in `pubspec.yaml` with real URLs.
- `flutter pub get`
- `flutter test`
- `dart analyze`
- Optional: `dart pub publish --dry-run`, then `dart pub publish`.
- Repo: https://github.com/AllinGaming/pdf_struct_extractor

## Testing
```
dart test
```
Uses an embedded sample PDF and limits to the first page for speed.

## Local example
- Run the CLI: `flutter pub run pdf_struct_extractor path/to/your.pdf > output.json`
- Or run the example app: `dart run example/main.dart > example_output.json` (uses embedded sample if no path given)
- Limit pages: `MAX_PAGES=3 dart run example/main.dart path/to/your.pdf`

Flutter example:
- Located at `example/flutter_app`.
- Run: `cd example/flutter_app && flutter pub get && flutter run`
- It uses an embedded sample PDF and shows the structured JSON in a scrollable view (expandable pages/blocks).
- For web, ensure pdfrx WASM assets are available and included (see web setup below).

## Using in Flutter (in-memory bytes)
```dart
import 'package:file_picker/file_picker.dart';
import 'package:pdf_struct_extractor/pdf_struct_extractor.dart';

Future<void> pickAndExtract() async {
  final res = await FilePicker.platform.pickFiles(withData: true, type: FileType.custom, allowedExtensions: ['pdf']);
  if (res == null || res.files.single.bytes == null) return;
  final bytes = res.files.single.bytes!;
  final data = await PdfStructuredExtractor.extractFromBytes(bytes, sourceName: res.files.single.name);
  // data is your JSON-friendly Map
  print(data['meta']);
}
```
- Flutter web setup:
  - Ensure pdfrx WASM assets are available. In your web `index.html` include:
    - `assets/packages/pdfrx/assets/pdfium_client.js`
    - `assets/packages/pdfrx/assets/pdfium_worker.js`
  - Call `pdfrxFlutterInitialize()` before using `PdfStructuredExtractor` on web; the default `pdfiumModuleBaseUrl` points to `assets/packages/pdfrx/assets`.
  - For GitHub Pages or non-root hosting, adjust `base href` and asset paths accordingly.
  - Example `index.html` already includes the scripts; copy that pattern for your app.
