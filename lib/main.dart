// // import 'dart:developer';

// // import 'package:flutter/material.dart';
// // import 'package:image_picker/image_picker.dart';
// // import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// // import 'package:ocr_test_with_ml/ocr_page.dart';
// // import 'package:ocr_test_with_ml/weight_item_model.dart';

// // import 'ocr_service.dart';

// // void main() {
// //   runApp(const MyApp());
// // }

// // class MyApp extends StatelessWidget {
// //   const MyApp({super.key});
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       title: 'Receipt OCR Demo',
// //       theme: ThemeData(primarySwatch: Colors.blue),
// //       home: const OcrPage(),
// //     );
// //   }
// // }

// import 'dart:developer';
// import 'dart:io';
// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:google_generative_ai/google_generative_ai.dart';

// void main() {
//   runApp(const GeminiOCRApp());
// }

// class GeminiOCRApp extends StatelessWidget {
//   const GeminiOCRApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: "Gemini OCR Example",
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: const OCRPage(),
//     );
//   }
// }

// class OCRPage extends StatefulWidget {
//   const OCRPage({super.key});

//   @override
//   State<OCRPage> createState() => _OCRPageState();
// }

// class _OCRPageState extends State<OCRPage> {
//   File? selectedImage;
//   List<String> weights = [];
//   bool loading = false;

//   final ImagePicker picker = ImagePicker();

//   final String apiKey = "AIzaSyD9QtLNGAKoatwg2NhMKezdbPhAcnpW0GQ";

//   Future<void> pickImage() async {
//     final XFile? file = await picker.pickImage(source: ImageSource.gallery);

//     if (file == null) return;

//     setState(() {
//       selectedImage = File(file.path);
//       weights = [];
//     });

//     await extractWeightsGemini(File(file.path));
//   }

//   /// Gemini OCR + Weight Extraction
//   Future<void> extractWeightsGemini(File imageFile) async {
//     setState(() => loading = true);

//     try {
//       final model = GenerativeModel(model: "gemini-2.0-flash", apiKey: apiKey);

//       final bytes = await imageFile.readAsBytes();

//       //       final prompt = """
//       // Extract all weight values from this image.
//       // Each value MUST contain a number + unit (lb or kg).
//       // Return ONLY a JSON array of strings.
//       // Example: ["110.7 lb", "110.6 lb"]
//       // """;
//       //
//       //

//       final prompt = """
// Extract all text from this image.
// Return two results:

// 1. full_text: the complete raw text in one string
// 2. lines: JSON array of each line separately

// Format:
// {
//   "full_text": "...",
//   "lines": ["...", "..."]
// }
// """;

//       final response = await model.generateContent([Content.text(prompt), Content.data("image/jpeg", bytes)]);

//       log("Gemini Response: ${response.text}");
//       // String raw = response.text ?? "[]";

//       // // Remove formatting if Gemini wraps response
//       // raw = raw.replaceAll("```json", "").replaceAll("```", "");

//       // // Convert JSON array to list
//       // final List<dynamic> list = jsonDecode(raw);

//       // setState(() {
//       //   weights = list.map((e) => e.toString()).toList();
//       // });

//       setState(() {
//         weights = response.text != null ? [response.text!] : ["No text extracted"];
//       });
//     } catch (e) {
//       setState(() {
//         weights = ["ERROR: $e"];
//       });
//     }

//     setState(() => loading = false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Gemini OCR (Free)")),
//       floatingActionButton: FloatingActionButton(onPressed: pickImage, child: const Icon(Icons.image)),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             selectedImage == null ? const Text("Pick an image to extract weights") : Image.file(selectedImage!, height: 200),

//             const SizedBox(height: 20),

//             loading
//                 ? const CircularProgressIndicator()
//                 : Expanded(
//                     child: ListView.builder(
//                       itemCount: weights.length,
//                       itemBuilder: (context, index) => Card(child: ListTile(title: Text(weights[index]))),
//                     ),
//                   ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() {
  runApp(const OCRApp());
}

class OCRApp extends StatelessWidget {
  const OCRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: "Gemini OCR Text List", home: const OCRPage());
  }
}

class OCRPage extends StatefulWidget {
  const OCRPage({super.key});

  @override
  State<OCRPage> createState() => _OCRPageState();
}

class _OCRPageState extends State<OCRPage> {
  File? selectedImage;
  List<String> textList = [];
  bool loading = false;

  final picker = ImagePicker();

  final String apiKey = "AIzaSyD9QtLNGAKoatwg2NhMKezdbPhAcnpW0GQ";

  // 📸 Take photo from camera
  Future<void> pickFromCamera() async {
    final XFile? file = await picker.pickImage(source: ImageSource.camera);
    if (file != null) {
      selectedImage = File(file.path);
      await extractOCR(File(file.path));
      setState(() {});
    }
  }

  // 🖼 Pick from gallery (phone)
  Future<void> pickFromGallery() async {
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      selectedImage = File(file.path);
      await extractOCR(File(file.path));
      setState(() {});
    }
  }

  // 💻 Pick file from laptop/desktop
  Future<void> pickFromFileBrowser() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.single.path != null) {
      selectedImage = File(result.files.single.path!);
      await extractOCR(File(result.files.single.path!));
      setState(() {});
    }
  }

  // 🔥 Gemini OCR that returns text list (line by line)
  Future<void> extractOCR(File image) async {
    setState(() {
      loading = true;
      textList = [];
    });

    try {
      final model = GenerativeModel(model: "gemini-2.0-flash", apiKey: apiKey);

      final bytes = await image.readAsBytes();

      final prompt = """
Extract all text from this image.
Return each line as a JSON array.
Example: ["line1", "line2", "line3"]
""";

      final response = await model.generateContent([Content.text(prompt), Content.data("image/jpeg", bytes)]);

      String raw = response.text ?? "[]";

      raw = raw.replaceAll("```json", "").replaceAll("```", "");

      final List<dynamic> list = jsonDecode(raw);

      setState(() {
        textList = list.map((e) => e.toString()).toList();
      });
    } catch (e) {
      textList = ["ERROR: $e"];
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gemini OCR → Text List")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            selectedImage == null ? const Text("Pick or capture an image") : Image.file(selectedImage!, height: 200),

            const SizedBox(height: 20),

            loading
                ? const CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: textList.length,
                      itemBuilder: (_, i) => Card(child: ListTile(title: Text(textList[i]))),
                    ),
                  ),
          ],
        ),
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: "camera",
            onPressed: pickFromCamera,
            label: const Text("Camera"),
            icon: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: "gallery",
            onPressed: pickFromGallery,
            label: const Text("Gallery"),
            icon: const Icon(Icons.photo),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: "file",
            onPressed: pickFromFileBrowser,
            label: const Text("File Picker"),
            icon: const Icon(Icons.file_open),
          ),
        ],
      ),
    );
  }
}
