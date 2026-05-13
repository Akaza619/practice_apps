import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_app/screens/screen3/search_provider.dart';

class MyWidget extends ConsumerWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("Counter App")),
      body: Column(
        mainAxisAlignment: .center,
        children: [
          TextField(
            onChanged: (value) {
              ref.read(searchProvider.notifier).search(value);
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final search = ref.watch(searchProvider);
              return Text(search.search);
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final ischange = ref.watch(
                (searchProvider).select((state) => state.ischange),
              );
              return Switch(
                value: ischange,
                onChanged: (value) {
                  ref.read(searchProvider.notifier).oschange(value);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
