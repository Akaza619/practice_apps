import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitora_app/controllers/auth_controller.dart';
import 'package:splitora_app/screens/forget_pass.dart';
import 'package:splitora_app/screens/signup.dart';
import 'package:splitora_app/theme/app_theme.dart';
import 'dart:ui';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool passwordVisible = false;
  bool isFormValid = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
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
                        ClipOval(
                          child: Image.asset(
                            'assets/split.jpg',
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Welcome Back",
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Login to your account",
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 30),

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
                                  value!.isEmpty
                                      ? "Password is required"
                                      : null,
                        ),
                        const SizedBox(height: 10),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Get.to(() => const ForgetPass()),
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        ElevatedButton(
                          onPressed:
                              isFormValid
                                  ? () {
                                    AuthController.instance.login(
                                      emailController.text.trim(),
                                      passwordController.text.trim(),
                                    );
                                  }
                                  : null,
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
                            "LOGIN",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        GestureDetector(
                          onTap: () => Get.to(() => const Signup()),
                          child: RichText(
                            text: const TextSpan(
                              text: "Don't have an account? ",
                              style: TextStyle(color: AppTheme.textSecondary),
                              children: [
                                TextSpan(
                                  text: "Register",
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: validator,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppTheme.iconColor),
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
