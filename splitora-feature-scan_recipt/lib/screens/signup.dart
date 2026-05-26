import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitora_app/controllers/auth_controller.dart';
import 'package:splitora_app/theme/app_theme.dart';
import 'dart:ui';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  bool passwordVisible = false;
  bool confirmPasswordVisible = false;
  bool isFormValid = false;

  Future<void> signUp() async {
    if (_formKey.currentState!.validate()) {
      AuthController.instance.register(
        emailController.text.trim(),
        passwordController.text.trim(),
        firstNameController.text.trim(),
        lastNameController.text.trim(),
        phoneController.text.trim(),
      );
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.backgroundDecoration,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: AppTheme.glassCardDecoration,
                  child: Form(
                    key: _formKey,
                    onChanged: () {
                      setState(() {
                        isFormValid =
                            _formKey.currentState?.validate() ?? false;
                      });
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Create Account",
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Join us today!",
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
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
                          keyboard: TextInputType.emailAddress,
                          validator:
                              (value) =>
                                  !GetUtils.isEmail(value!)
                                      ? "Enter a valid email"
                                      : null,
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
                            if (value.length != 10) return "Must be 10 digits";
                            if (!RegExp(r'^[789]').hasMatch(value)) {
                              return "Must start with 7, 8, or 9";
                            }
                            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                              return "Digits only";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        buildPasswordField(
                          controller: passwordController,
                          hint: "Password",
                          visible: passwordVisible,
                          onToggle:
                              () => setState(
                                () => passwordVisible = !passwordVisible,
                              ),
                          validator:
                              (value) =>
                                  value!.length < 7 ? "Min 7 characters" : null,
                        ),
                        const SizedBox(height: 15),
                        buildPasswordField(
                          controller: confirmPasswordController,
                          hint: "Confirm Password",
                          visible: confirmPasswordVisible,
                          onToggle:
                              () => setState(
                                () =>
                                    confirmPasswordVisible =
                                        !confirmPasswordVisible,
                              ),
                          validator:
                              (value) =>
                                  value != passwordController.text
                                      ? "Passwords do not match"
                                      : null,
                        ),
                        const SizedBox(height: 30),

                        ElevatedButton(
                          onPressed: isFormValid ? signUp : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.fabBackground,
                            foregroundColor: AppTheme.buttonForeground,
                            disabledBackgroundColor:
                                AppTheme.disabledButtonBackground,
                            disabledForegroundColor:
                                AppTheme.disabledButtonForeground,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 15,
                            ),
                            elevation: isFormValid ? 5 : 0,
                          ),
                          child: const Text(
                            "SIGN UP",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        GestureDetector(
                          onTap: () => Get.back(),
                          child: RichText(
                            text: const TextSpan(
                              text: "Already have an account? ",
                              style: TextStyle(color: AppTheme.textSecondary),
                              children: [
                                TextSpan(
                                  text: "Login",
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLength: maxLength,
      validator: validator,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppTheme.iconColor),
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textTertiary),
        counterText: "",
        filled: true,
        fillColor: AppTheme.inputFill,
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

  Widget buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool visible,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      validator: validator,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.iconColor),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            visible ? Icons.visibility : Icons.visibility_off,
            color: AppTheme.iconColor,
          ),
        ),
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textTertiary),
        filled: true,
        fillColor: AppTheme.inputFill,
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
