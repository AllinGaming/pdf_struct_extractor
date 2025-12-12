import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pdf_struct_extractor/pdf_struct_extractor.dart';

void main() {
  runApp(const PdfStructExampleApp());
}

class PdfStructExampleApp extends StatelessWidget {
  const PdfStructExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Struct Extractor',
      theme: ThemeData(useMaterial3: true),
      home: const ExtractPage(),
    );
  }
}

class ExtractPage extends StatefulWidget {
  const ExtractPage({super.key});

  @override
  State<ExtractPage> createState() => _ExtractPageState();
}

class _ExtractPageState extends State<ExtractPage> {
  Map<String, dynamic>? _data;
  String _raw = 'Tap "Extract" to process sample.pdf';
  bool _loading = false;
  bool _initialized = false;
  final ScrollController _treeController = ScrollController();
  final ScrollController _rawController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initPdfrx();
  }

  Future<void> _initPdfrx() async {
    if (kIsWeb) {
      await pdfrxFlutterInitialize();
    }
    setState(() {
      _initialized = true;
    });
  }

  Future<void> _extractSample() async {
    if (!_initialized) {
      setState(() {
        _raw = 'Initializing...';
      });
      await _initPdfrx();
    }
    setState(() {
      _loading = true;
      _raw = 'Running...';
      _data = null;
    });
    try {
      final data = await PdfStructuredExtractor.extractFromBytes(
        _samplePdfBytes,
        sourceName: 'sample.pdf',
      );
      setState(() {
        _data = data;
        _raw = const JsonEncoder.withIndent('  ').convert(data);
      });
    } catch (e, st) {
      setState(() {
        _raw = 'Error: $e\n$st';
        _data = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Struct Extractor')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _loading ? null : _extractSample,
                  child: const Text('Extract sample.pdf'),
                ),
                const SizedBox(width: 12),
                if (_loading)
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _data == null
                  ? SelectableText(
                      _raw,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 12),
                    )
                  : DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          const TabBar(
                            tabs: [
                              Tab(text: 'Tree'),
                              Tab(text: 'Raw'),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildTreeView(),
                                Scrollbar(
                                  controller: _rawController,
                                  thumbVisibility: true,
                                  child: SingleChildScrollView(
                                    controller: _rawController,
                                    padding: const EdgeInsets.all(8),
                                    child: SelectableText(
                                      _raw,
                                      style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeView() {
    final pages = (_data?['pages'] as List?) ?? const [];
    return Scrollbar(
      controller: _treeController,
      thumbVisibility: true,
      child: ListView.separated(
        controller: _treeController,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final page = pages[index] as Map<String, dynamic>;
          final blocks = (page['blocks'] as List?) ?? const [];
          return ExpansionTile(
            title: Text('Page ${page['page']} • ${blocks.length} blocks'),
            subtitle:
                Text('Size: ${page['pageWidth']} x ${page['pageHeight']} pt'),
            children: blocks
                .map((b) => _buildBlockTile(b as Map<String, dynamic>))
                .toList(),
          );
        },
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: pages.length,
      ),
    );
  }

  Widget _buildBlockTile(Map<String, dynamic> block) {
    final type = (block['type'] ?? '').toString();
    final text = (block['text'] ?? '').toString();
    final indent = block['indent'];
    final marker = block['marker'];
    final ordered = block['ordered'];
    String subtitle = '';
    if (indent != null) {
      subtitle += 'indent: $indent ';
    }
    if (marker != null && marker.toString().isNotEmpty) {
      subtitle += 'marker: $marker ';
    }
    if (ordered != null) {
      subtitle += 'ordered: $ordered ';
    }
    final displayText = text.length > 200 ? '${text.substring(0, 200)}…' : text;
    return ListTile(
      dense: true,
      title: Text(
          '${type.toUpperCase()}${subtitle.isNotEmpty ? ' • $subtitle' : ''}'),
      subtitle: displayText.isEmpty ? null : Text(displayText),
    );
  }

  Uint8List get _samplePdfBytes =>
      Uint8List.fromList(base64Decode(_samplePdfBase64));
}

const _samplePdfBase64 =
    'JVBERi0xLjQKJeLjz9MKMSAwIG9iago8PCAvVHlwZSAvQ2F0YWxvZyAvUGFnZXMgMiAwIFIgPj4KZW5kb2JqCjIgMCBvYmoKPDwgL1R5cGUgL1BhZ2VzIC9Db3VudCAxIC9LaWRzIFszIDAgUl0gPj4KZW5kb2JqCjMgMCBvYmoKPDwgL1R5cGUgL1BhZ2UgL1BhcmVudCAyIDAgUiAvTWVkaWFCb3ggWzAgMCA2MTIgNzkyXSAvUmVzb3VyY2VzIDw8IC9Gb250IDw8IC9GMSA1IDAgUiA+PiA+PiAvQ29udGVudHMgNCAwIFIgPj4KZW5kb2JqCjQgMCBvYmoKPDwgL0xlbmd0aCA0MSA+PgpzdHJlYW0KQlQgL0YxIDI0IFRmIDEwMCA3MDAgVGQgKEhlbGxvIFBERikgVGogRVQKZW5kc3RyZWFtCmVuZG9iago1IDAgb2JqCjw8IC9UeXBlIC9Gb250IC9TdWJ0eXBlIC9UeXBlMSAvQmFzZUZvbnQgL0hlbHZldGljYSA+PgplbmRvYmoKeHJlZgowIDYKMDAwMDAwMDAwMCA2NTUzNSBmIAowMDAwMDAwMDE1IDAwMDAwIG4gCjAwMDAwMDAwNjQgMDAwMDAgbiAKMDAwMDAwMDEyMSAwMDAwMCBuIAowMDAwMDAwMjQ3IDAwMDAwIG4gCjAwMDAwMDAzMzggMDAwMDAgbiAKdHJhaWxlcgo8PCAvU2l6ZSA2IC9Sb290IDEgMCBSID4+CnN0YXJ0eHJlZgo0MDgKJSVFT0YK';
