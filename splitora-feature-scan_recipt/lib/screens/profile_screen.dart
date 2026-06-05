import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:splitora_app/controllers/auth_controller.dart';
import 'package:splitora_app/theme/app_theme.dart';
import 'package:splitora_app/widgets/user_avatar.dart';
import 'dart:ui';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      if (user != null) {
        DocumentSnapshot doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user!.uid)
                .get();
        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>;
          firstNameController.text = data['firstName'] ?? '';
          lastNameController.text = data['lastName'] ?? '';
          emailController.text = data['email'] ?? '';
          phoneController.text = data['phone'] ?? '';
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch user data: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      await AuthController.instance.updateUser(
        firstNameController.text.trim(),
        lastNameController.text.trim(),
        phoneController.text.trim(),
      );
    }
  }

  void _showImagePickerOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.textPrimary),
              title: const Text('Gallery', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.textPrimary),
              title: const Text('Camera', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.camera);
              },
            ),
            if (AuthController.instance.photoURL.value.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Remove Image', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Get.back();
                  AuthController.instance.clearProfileImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    await AuthController.instance.pickAndSaveProfileImage(source);
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.backgroundDecoration,
        child:
            isLoading
                ? const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.textPrimary,
                  ),
                )
                : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 40,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          decoration: AppTheme.glassCardDecoration,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Obx(() {
                                  final url = AuthController.instance.photoURL.value;
                                  return GestureDetector(
                                    onTap: _showImagePickerOptions,
                                    child: Stack(
                                      children: [
                                        UserAvatar(
                                          radius: 50,
                                          photoURL: url,
                                          displayName:
                                              '${firstNameController.text} ${lastNameController.text}',
                                          firstName: firstNameController.text,
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(
                                              color: AppTheme.fabBackground,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt,
                                              size: 18,
                                              color: AppTheme.buttonForeground,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 20),
                                const Text(
                                  "Profile Details",
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 30),

                                buildTextFormField(
                                  controller: firstNameController,
                                  hint: "First Name",
                                  icon: Icons.person,
                                  validator:
                                      (value) =>
                                          value!.trim().isEmpty
                                              ? "First Name is required"
                                              : null,
                                ),
                                const SizedBox(height: 15),
                                buildTextFormField(
                                  controller: lastNameController,
                                  hint: "Surname",
                                  icon: Icons.person_outline,
                                  validator:
                                      (value) =>
                                          value!.trim().isEmpty
                                              ? "Surname is required"
                                              : null,
                                ),
                                const SizedBox(height: 15),
                                buildTextFormField(
                                  controller: emailController,
                                  hint: "Email",
                                  icon: Icons.email,
                                  readOnly: true,
                                ),
                                const SizedBox(height: 15),
                                buildTextFormField(
                                  controller: phoneController,
                                  hint: "Phone Number",
                                  icon: Icons.phone,
                                  keyboard: TextInputType.phone,
                                  maxLength: 10,
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return "Phone number is required";
                                    }
                                    if (value.length != 10) {
                                      return "Must be 10 digits";
                                    }
                                    if (!RegExp(r'^[789]').hasMatch(value)) {
                                      return "Must start with 7, 8, or 9";
                                    }
                                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                      return "Digits only";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 30),

                                ElevatedButton(
                                  onPressed: _updateProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.fabBackground,
                                    foregroundColor: AppTheme.buttonForeground,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 50,
                                      vertical: 15,
                                    ),
                                  ),
                                  child: const Text(
                                    "UPDATE PROFILE",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                TextButton.icon(
                                  onPressed: () {
                                    AuthController.instance.signOut();
                                  },
                                  icon: const Icon(
                                    Icons.logout,
                                    color: AppTheme.textSecondary,
                                  ),
                                  label: const Text(
                                    "Logout",
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
      ),
    );
  }

  Widget buildTextFormField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    int? maxLength,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLength: maxLength,
      readOnly: readOnly,
      validator: validator,
      style: TextStyle(
        color: readOnly ? AppTheme.textSecondary : AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppTheme.iconColor),
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textTertiary),
        counterText: "",
        filled: true,
        fillColor: readOnly ? AppTheme.readOnlyFill : AppTheme.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(
          color: AppTheme.errorColor,
          fontWeight: FontWeight.bold,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
      ),
    );
  }
}
