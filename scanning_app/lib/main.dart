import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart' as mlkit;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: BarcodeScannerPage(cameras: cameras),
  ));
}

class BarcodeScannerPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const BarcodeScannerPage({super.key, required this.cameras});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  CameraController? _controller;
  final scanner = mlkit.BarcodeScanner();
  
  String barcode = '', error = '';
  bool isDetecting = false, initialized = false, showQuantityInput = false;
  final TextEditingController quantityController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    if (widget.cameras.isEmpty) {
      setState(() => error = 'No cameras found');
      return;
    }
    try {
      _controller = CameraController(widget.cameras.first, ResolutionPreset.medium);
      await _controller!.initialize();
      setState(() => initialized = true);
      await _controller!.startImageStream(_processImage);
    } catch (e) {
      setState(() => error = 'Init error: $e');
      if (kDebugMode) print(e);
    }
  }

  Future<void> _processImage(CameraImage image) async {
    if (isDetecting) return;
    isDetecting = true;
    try {
      final allBytes = image.planes.expand((p) => p.bytes).toList();
      final bytes = WriteBuffer()..putUint8List(Uint8List.fromList(allBytes));
      final inputImage = mlkit.InputImage.fromBytes(
        bytes: bytes.done().buffer.asUint8List(),
        metadata: mlkit.InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: mlkit.InputImageRotation.values.firstWhere(
              (r) => r.index == widget.cameras.first.sensorOrientation ~/ 90),
          format: mlkit.InputImageFormatValue.fromRawValue(image.format.raw)!,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );

      final results = await scanner.processImage(inputImage);
      if (results.isNotEmpty) {
        final detectedCode = results.first.displayValue ?? '';
        if (detectedCode != barcode) {
          setState(() {
            barcode = detectedCode;
            showQuantityInput = true;
            quantityController.text = '1';
          });
        }
      }
    } catch (e) {
      if (kDebugMode) print('Scan error: $e');
    }
    isDetecting = false;
  }

  Future<void> _writeToCsv(String barcode, String quantity) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/stock.csv';
    final file = File(path);
    print('✅ Saved CSV to: $path');

    bool fileExists = await file.exists();

    List<List<dynamic>> rows = [];

    if (!fileExists) {
      rows.add(['Barcode', 'Quantity']);
    }

    rows.add([barcode, quantity]);

    String csv = const ListToCsvConverter().convert(rows);

    if (fileExists) {
      final oldContent = await file.readAsString();
      csv = oldContent.trim() + '\n' + csv.split('\n').last; // append only new line
    }

    await file.writeAsString(csv);
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    scanner.close();
    quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (error.isNotEmpty) return _buildError();
    if (!initialized) return _buildLoading();

    return Scaffold(
      appBar: AppBar(title: const Text('Barcode Scanner')),
      body: Stack(
        children: [
          if (_controller != null) CameraPreview(_controller!),
          _overlay(),
        ],
      ),
    );
  }

  Widget _overlay() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(50),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('Align barcode in frame', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Scanned Barcode:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(barcode.isEmpty ? 'No barcode' : barcode),
              const SizedBox(height: 10),

              if (showQuantityInput)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Quantity'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final qty = quantityController.text;
                        if (barcode.isNotEmpty && qty.isNotEmpty && int.tryParse(qty) != null) {
                          await _writeToCsv(barcode, qty);
                          if (mounted) {
                            setState(() {
                              barcode = '';
                              showQuantityInput = false;
                              quantityController.clear();
                            });
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Added to stock')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invalid quantity')),
                          );
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),

              if (!showQuantityInput)
                ElevatedButton(
                  onPressed: () => setState(() => barcode = ''),
                  child: const Text('Clear'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError() => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _setupCamera, child: const Text('Retry')),
            ],
          ),
        ),
      );

  Widget _buildLoading() => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [CircularProgressIndicator(), SizedBox(height: 12), Text('Initializing camera...')],
          ),
        ),
      );
}
