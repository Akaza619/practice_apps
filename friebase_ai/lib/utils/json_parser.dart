import 'dart:convert';

class JsonParser {
  static Map<String, dynamic>? parseJsonString(String response) {
    try {
      // Remove any potential markdown blocks or leading/trailing whitespace
      String cleanString = response.trim();
      if (cleanString.startsWith('```json')) {
        cleanString = cleanString.substring(7);
      } else if (cleanString.startsWith('```')) {
        cleanString = cleanString.substring(3);
      }
      if (cleanString.endsWith('```')) {
        cleanString = cleanString.substring(0, cleanString.length - 3);
      }
      cleanString = cleanString.trim();

      return jsonDecode(cleanString) as Map<String, dynamic>;
    } catch (e) {
      print('Error parsing JSON: $e');
      return null;
    }
  }
}
