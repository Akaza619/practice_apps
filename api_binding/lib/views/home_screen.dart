import 'package:api_binding/views/api_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();

  Future<void> storeUser() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passController.text.trim(),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("User Stored Successfully")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => ApiScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text("Home Screen")),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            TextField(
              textAlign: TextAlign.start,
              cursorHeight: 20,
              controller: emailController,
            ),
            SizedBox(height: 20),
            TextField(
              textAlign: TextAlign.start,
              cursorHeight: 20,
              controller: passController,
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: storeUser, child: Text("Login")),
          ],
        ),
      ),
    );
  }
}
