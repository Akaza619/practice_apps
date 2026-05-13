import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_app/screens/screen2%20yt2/fake_api_service.dart';

final fakeApiProvider = Provider((_) => FakeApiService());

final greetingFutureProvider = FutureProvider((ref) async {
  final service = ref.read(fakeApiProvider);
  return await service.fetchGreeting();
});

class GreetingScreen extends ConsumerWidget {
  const GreetingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greetingAsynce = ref.watch(greetingFutureProvider);
    return Scaffold(
      appBar: AppBar(title: const Text("Async Greeting")),
      body: Center(
        child: greetingAsynce.when(
          data: (greeting) => Text(greeting, style: TextStyle(fontSize: 20)),
          error: (error, stackTrace) => Column(
            mainAxisSize: .min,
            children: [
              Text(error.toString()),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () {
                  return ref.refresh(greetingFutureProvider);
                },
                child: const Text("Retry"),
              ),
            ],
          ),
          loading: () => CircularProgressIndicator(),
        ),
      ),
    );
  }
}
