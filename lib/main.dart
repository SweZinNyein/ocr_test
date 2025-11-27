import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ocr_test_with_ml/ocr_page.dart';
import 'package:ocr_test_with_ml/weight_item_model.dart';

import 'ocr_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Receipt OCR Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const OcrPage(),
    );
  }
}

// class OcrPage extends StatefulWidget {
//   const OcrPage({super.key});
//   @override
//   State<OcrPage> createState() => _OcrPageState();
// }

// class _OcrPageState extends State<OcrPage> {
//   final picker = ImagePicker();
//   final ocrService = OcrService();

//   bool loading = false;
//   List<WeightItem> items = [];
//   Map<String, dynamic>? total;

//   Future<void> _pickImage() async {
//     final picked = await picker.pickImage(source: ImageSource.gallery);
//     if (picked == null) return;
//     setState(() {
//       loading = true;
//       items = [];
//       total = null;
//     });

//     try {
//       final inputImage = InputImage.fromFilePath(picked.path);
//       final recognized = await ocrService.processImage(inputImage);

//       // debug: print recognized text blocks
//       debugPrint('--- recognized whole text ---');
//       debugPrint(recognized.text);

//       // parse weights
//       final parsed = ocrService.parseWeightsFromRecognizedText(recognized);

//       // if empty, attempt fallback: try per-line heuristics using line.text
//       if (parsed.isEmpty) {
//         for (final b in recognized.blocks) {
//           for (final l in b.lines) {
//             final alt = ocrService.parseLineWithHeuristics(l.text);
//             if (alt != null) parsed.add(alt);
//           }
//         }
//       }

//       final parsedTotal = ocrService.parseTotalFromRecognizedText(recognized);

//       // debug prints
//       for (int i = 0; i < parsed.length; i++) {
//         debugPrint('[log] $i ${parsed[i].no} ${parsed[i].weight} ${parsed[i].unit}');
//       }
//       if (parsedTotal != null) {
//         debugPrint('[log] TOTAL ${parsedTotal['total']} ${parsedTotal['unit']}');
//       }

//       setState(() {
//         items = parsed;
//         total = parsedTotal;
//         loading = false;
//       });
//     } catch (e, st) {
//       debugPrint('OCR failed: $e\n$st');
//       setState(() => loading = false);
//       rethrow;
//     }
//   }

//   Widget _buildList() {
//     if (loading) return const Center(child: CircularProgressIndicator());
//     if (items.isEmpty) return const Text('No items parsed yet.');

//     return Expanded(
//       child: ListView.builder(
//         itemCount: items.length,
//         itemBuilder: (c, i) {
//           final it = items[i];
//           log('${it.weight} ${it.unit}');
//           return ListTile(leading: Text('${it.no}'), title: Text('${it.weight} ${it.unit}'), subtitle: Text('index $i'));
//         },
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Receipt OCR (robust)')),
//       body: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           children: [
//             ElevatedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.photo), label: const Text('Pick receipt image')),
//             const SizedBox(height: 12),
//             _buildList(),
//             if (total != null)
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 8),
//                 child: Text(
//                   'Total: ${total!['total']} ${total!['unit']}',
//                   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
