import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;

class VisionOcrService {
  final String apiKey;

  VisionOcrService(this.apiKey);

  Future<String> extractText(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final url = Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$apiKey');

    final payload = {
      "requests": [
        {
          "image": {"content": base64Image},
          "features": [
            {"type": "TEXT_DETECTION"},
          ],
        },
      ],
    };

    final response = await http.post(url, headers: {"Content-Type": "application/json"}, body: jsonEncode(payload));

    final data = jsonDecode(response.body);

    //  log("[VisionOcrService] response: $data");

    log("${data['responses'][0]['fullTextAnnotation']['text'] ?? ''}");

    final text = data['responses'][0]['fullTextAnnotation']['text'] ?? '';

    return text;
  }



Future<List<String>> extractWeightsFromImage(File imageFile) async {
  final bytes = await imageFile.readAsBytes();
  final base64Image = base64Encode(bytes);

  final url = Uri.parse(
      'https://vision.googleapis.com/v1/images:annotate?key=$apiKey');

  final payload = {
    "requests": [
      {
        "image": {"content": base64Image},
        "features": [
          {"type": "TEXT_DETECTION"},
        ],
      },
    ],
  };

  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(payload),
  );

  final data = jsonDecode(response.body);

  // Extract full OCR text
  final fullText =
      data['responses']?[0]?['fullTextAnnotation']?['text'] ?? '';

  log("🔍 OCR Text:\n$fullText");

  // Extract only values like "110.7 lb" or "90 kg"
  final regex = RegExp(r'(\d+(\.\d+)?\s*(lb|kg))', caseSensitive: false);
  final matches = regex.allMatches(fullText);

  final weights = matches.map((m) => m.group(0)!).toList();

  log("📦 Extracted Weights: $weights");

  return weights;
}

}
