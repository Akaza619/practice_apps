import 'dart:math';

class FakeApiService {
  Future<String> fetchGreeting() async {
    await Future.delayed(const Duration(seconds: 2));
    if (Random().nextDouble() < 0.9) {
      throw Exception("Failed to fetch greeting");
    }
    return "Hello from Async!";
  }
}
