import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:riverpod_app/screens/home_screen.dart';
// import 'package:riverpod_app/screens/screen2/slider_screen.dart';
// import 'package:riverpod_app/screens/screen3/search_home_screen.dart';
import 'package:riverpod_app/screens/screen4/home_screen.dart';
// import 'package:riverpod_app/screens/screen4/consumer_wid.dart';
// import 'package:riverpod_app/screens/screen5%20yt2/future_provider.dart';
// import 'package:riverpod_app/screens/my_home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(debugShowCheckedModeBanner: false, home: HomeScreen()),
    );
  }
}
