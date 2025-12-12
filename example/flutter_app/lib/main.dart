import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kIsWeb;
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
      final bytes = await rootBundle.load('assets/sample.pdf');
      final data = await PdfStructuredExtractor.extractFromBytes(
        Uint8List.sublistView(bytes.buffer.asUint8List()),
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
}
