import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splitora_app/screens/main_screen.dart';
import 'package:splitora_app/screens/login.dart';

class AuthController extends GetxController {
  static AuthController instance = Get.find();
  late Rx<User?> _user;
  FirebaseAuth auth = FirebaseAuth.instance;
  RxString photoURL = ''.obs;

  @override
  void onReady() {
    super.onReady();
    _user = Rx<User?>(auth.currentUser);
    _user.bindStream(auth.userChanges());
    ever(_user, _initialScreen);
    _loadPhotoURL();
  }

  Future<void> _loadPhotoURL() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (doc.exists) {
      final url = doc.data()?['photoURL'] as String? ?? '';
      photoURL.value = url;
    }
  }

  Future<String?> pickAndSaveProfileImage([ImageSource source = ImageSource.gallery]) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null) return null;

    final uid = auth.currentUser?.uid;
    if (uid == null) return null;

    // Delete old local image if exists
    if (photoURL.value.isNotEmpty) {
      final oldFile = File(photoURL.value);
      if (oldFile.existsSync()) {
        await oldFile.delete();
      }
    }

    // Save to local app directory
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${appDir.path}/profile_images');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    final newPath = '${imageDir.path}/$uid.jpg';
    await File(picked.path).copy(newPath);

    // Save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_$uid', newPath);

    // Save to Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'photoURL': newPath});

    photoURL.value = newPath;
    return newPath;
  }

  Future<void> clearProfileImage() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    // Delete local file
    if (photoURL.value.isNotEmpty) {
      final file = File(photoURL.value);
      if (file.existsSync()) {
        await file.delete();
      }
    }

    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_image_$uid');

    // Clear Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'photoURL': ''});

    photoURL.value = '';
  }

  Future<String?> getLocalProfileImage() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('profile_image_$uid');
  }

  void _initialScreen(User? user) {
    if (_isSigningUp) return;
    if (user == null) {
      Get.offAll(() => const Login());
    } else {
      Get.offAll(() => const MainScreen());
    }
  }

  bool _isSigningUp = false;

  void register(
    String email,
    String password,
    String firstName,
    String lastName,
    String phone,
  ) async {
    _isSigningUp = true;
    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      User? user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
          'phone': phone,
          'displayName': "$firstName $lastName",
          'photoURL': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await auth.signOut();
      _isSigningUp = false;
      Get.offAll(() => const Login());

      Get.snackbar(
        "Success",
        "Account created successfully. Please login.",
        backgroundColor: Colors.green.shade200,
      );
    } on FirebaseAuthException catch (e) {
      _isSigningUp = false;
      Get.snackbar(
        "Error",
        e.message ?? "Registration failed",
        backgroundColor: Colors.red.shade200,
      );
    }
  }

  void login(String email, password) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
      Get.snackbar(
        "Success",
        "Login successful",
        backgroundColor: Colors.green.shade200,
      );
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        "Error",
        e.message ?? "Login failed",
        backgroundColor: Colors.red.shade200,
      );
    }
  }

  void signOut() async {
    await auth.signOut();
  }

  void resetPassword(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
      Get.snackbar(
        "Success",
        "Password reset email sent",
        backgroundColor: Colors.green.shade200,
      );
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        "Error",
        e.message ?? "Failed to send reset email",
        backgroundColor: Colors.red.shade200,
      );
    }
  }

  Future<void> updateUser(
    String firstName,
    String lastName,
    String phone,
  ) async {
    try {
      User? user = auth.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'firstName': firstName,
              'lastName': lastName,
              'phone': phone,
              'displayName': "$firstName $lastName",
            });
        Get.snackbar(
          "Success",
          "Profile updated successfully",
          backgroundColor: Colors.green.shade200,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to update profile",
        backgroundColor: Colors.red.shade200,
      );
    }
  }
}
