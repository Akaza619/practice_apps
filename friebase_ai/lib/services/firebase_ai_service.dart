import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../utils/json_parser.dart';

class FirebaseAiService {
  final GenerativeModel _model;

  FirebaseAiService(String apiKey)
      : _model = GenerativeModel(
          model: 'gemini-flash-latest', // Fallback to latest flash model to fix free tier limit 0 issue
          apiKey: apiKey,
        );

  Future<Map<String, dynamic>?> analyzeReceipt(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final prompt = TextPart('''
Analyze this image. First, check whether the uploaded image is actually a valid receipt, bill, or invoice. 
If the image is not a receipt or bill, you must return exactly this JSON response: {"error":"You have captured the wrong image or uploaded the wrong image."}.

If the image is a valid receipt or bill, extract only the essential information needed for a simple and clean table view. 
You must return only raw JSON in the following format:

{
"bill_name": "string or null",
"items": [
{
"item_name": "string or null",
"item_count": number or null,
"unit_price": number or null,
"final_price": number or null
}
],
"gst_percent": number or null,
"gst_amount": number or null,
"total_amount": number or null
}

Rules:
* If any value is missing, unreadable, or not present on the receipt, set it to null.
* Do not guess any values.
* Return only valid raw JSON.
* Do not include markdown, code blocks, explanations, or any extra text.
''');

      final imageParts = [
        DataPart('image/jpeg', imageBytes), // Adjust mime type if necessary based on actual image
      ];

      final response = await _model.generateContent([
        Content.multi([prompt, ...imageParts])
      ]);

      if (response.text != null) {
        return JsonParser.parseJsonString(response.text!);
      }
      return null;
    } catch (e) {
      print('Error in analyzeReceipt: $e');
      return {"error": "Failed to analyze image: \$e"};
    }
  }
}
