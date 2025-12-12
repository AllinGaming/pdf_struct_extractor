import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_json_view/flutter_json_view.dart';
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

  Future<void> _extractSample() async {
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
                                Container(
                                  color: Colors.grey.shade50,
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(8),
                                    child: JsonView.map(
                                      _data!,
                                    ),
                                  ),
                                ),
                                SelectableText(
                                  _raw,
                                  style: const TextStyle(
                                      fontFamily: 'monospace', fontSize: 12),
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
}
