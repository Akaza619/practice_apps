import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/*
  use of the provider for in which we can not change the value,
  which is in the global state just listen that value

*/

final hello = Provider<String>((ref) {
  return "Omkar";
});

final age = Provider<int>((ref) {
  return 23;
});

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key});

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final subscribe = ref.watch(hello);
    final temp = ref.watch(age);
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Text("$subscribe age is  $temp")),
    );
  }
}

// class MyHomePage extends ConsumerWidget {
//   const MyHomePage({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final subscribe = ref.watch(hello);
//     final temp = ref.watch(age);
//     return Scaffold(
//       appBar: AppBar(),
//       body: Center(child: Text("$subscribe age is  $temp")),
//     );
//   }
// }
