import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final textProvider = StateProvider((ref) {
  return '';
});

class StatefulConsumerTutorial extends ConsumerStatefulWidget {
  const StatefulConsumerTutorial({super.key});

  @override
  ConsumerState<StatefulConsumerTutorial> createState() =>
      _StatefulConsumerTutorialState();
}

class _StatefulConsumerTutorialState
    extends ConsumerState<StatefulConsumerTutorial> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(() {
      ref.read(textProvider.notifier).state = _controller.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = ref.watch(textProvider);
    return Scaffold(
      appBar: AppBar(title: const Text("Text Form")),
      body: Column(
        children: [
          TextFormField(controller: _controller),
          const SizedBox(height: 20),
          Text("You typed: $text"),
        ],
      ),
    );
  }
}
