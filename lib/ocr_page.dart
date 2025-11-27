import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:ocr_test_with_ml/vision_ocr.dart';

class OcrPage extends StatefulWidget {
  const OcrPage({super.key});

  @override
  State<OcrPage> createState() => _OcrPageState();
}

class _OcrPageState extends State<OcrPage> {
  final picker = ImagePicker();
  final vision = VisionOcrService("AIzaSyDs9GlLOTjgRJXFeaQH_WbCHL0y9-lsU_w");

  String ocrResult = "";

  Future<void> pickAndScan() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final imageFile = File(picked.path);

    setState(() => ocrResult = "Reading...");

    final text = await vision.extractText(imageFile);

    setState(() => ocrResult = text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Google Vision OCR")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(onPressed: pickAndScan, child: Text("Pick Receipt Image")),
            SizedBox(height: 20),
            Expanded(child: SingleChildScrollView(child: Text(ocrResult))),
          ],
        ),
      ),
    );
  }
}
