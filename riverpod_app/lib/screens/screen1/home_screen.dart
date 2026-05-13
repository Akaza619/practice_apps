import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

final counter = StateProvider<int>((ref) {
  return 0;
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print("build1");
    return Scaffold(
      appBar: AppBar(title: const Text("Counter App")),
      body: Column(
        children: [
          Consumer(
            builder: (context, ref, child) {
              final count = ref.watch(counter);
              print("build2");
              return Center(
                child: Text(
                  count.toString(),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                ),
              );
            },
          ),
          Row(
            mainAxisAlignment: .center,
            children: [
              ElevatedButton(
                onPressed: () {
                  ref.read(counter.notifier).state--;
                },
                child: Text(
                  "-",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                ),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {
                  ref.read(counter.notifier).state++;
                },
                child: Text(
                  "+",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
