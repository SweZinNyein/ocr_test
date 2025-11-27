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

    final text = data['responses'][0]['fullTextAnnotation']['text'] ?? '';

    return text;
  }
}
