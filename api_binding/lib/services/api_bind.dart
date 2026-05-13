import 'dart:convert';

import 'package:api_binding/models/api_model.dart';
import 'package:http/http.dart' as http;

class ApiBind {
  Future<dynamic> fetchData() async {
    final response = await http.get(
      Uri.parse("https://api.coinranking.com/v2/coins"),
    );
    if (response.statusCode == 200) {
      return ApiModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Data not fetch!");
    }
  }
}
