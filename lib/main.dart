// import 'dart:developer';

// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import 'package:ocr_test_with_ml/ocr_page.dart';
// import 'package:ocr_test_with_ml/weight_item_model.dart';

// import 'ocr_service.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Receipt OCR Demo',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: const OcrPage(),
//     );
//   }
// }

import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() {
  runApp(const GeminiOCRApp());
}

class GeminiOCRApp extends StatelessWidget {
  const GeminiOCRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Gemini OCR Example",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const OCRPage(),
    );
  }
}

class OCRPage extends StatefulWidget {
  const OCRPage({super.key});

  @override
  State<OCRPage> createState() => _OCRPageState();
}

class _OCRPageState extends State<OCRPage> {
  File? selectedImage;
  List<String> weights = [];
  bool loading = false;

  final ImagePicker picker = ImagePicker();

  final String apiKey = "AIzaSyAhLhr1ybESLtq5CPakfvUcFxe8VCxPGbo";

  Future<void> pickImage() async {
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    setState(() {
      selectedImage = File(file.path);
      weights = [];
    });

    await extractWeightsGemini(File(file.path));
  }

  /// Gemini OCR + Weight Extraction
  Future<void> extractWeightsGemini(File imageFile) async {
    setState(() => loading = true);

    try {
      final model = GenerativeModel(model: "gemini-2.0-flash", apiKey: apiKey);

      final bytes = await imageFile.readAsBytes();

      final prompt = """
Extract all weight values from this image.
Each value MUST contain a number + unit (lb or kg).
Return ONLY a JSON array of strings.
Example: ["110.7 lb", "110.6 lb"]
""";       

      final response = await model.generateContent([Content.text(prompt), Content.data("image/jpeg", bytes)]);

      String raw = response.text ?? "[]";

      // Remove formatting if Gemini wraps response
      raw = raw.replaceAll("```json", "").replaceAll("```", "");

      // Convert JSON array to list
      final List<dynamic> list = jsonDecode(raw);

      setState(() {
        weights = list.map((e) => e.toString()).toList();
      });
    } catch (e) {
      setState(() {
        weights = ["ERROR: $e"];
      });
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gemini OCR (Free)")),
      floatingActionButton: FloatingActionButton(onPressed: pickImage, child: const Icon(Icons.image)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            selectedImage == null ? const Text("Pick an image to extract weights") : Image.file(selectedImage!, height: 200),

            const SizedBox(height: 20),

            loading
                ? const CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: weights.length,
                      itemBuilder: (context, index) => Card(child: ListTile(title: Text(weights[index]))),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
