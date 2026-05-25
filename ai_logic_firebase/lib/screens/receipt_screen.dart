// receipt_screen.dart
// Screen 1 – Receipt Scanner Entry Point
// Allows the user to pick an image from the camera or gallery,
// then navigates to ReceiptProcessingScreen.

import 'dart:io';
import 'package:ai_logic_firebase/service/receipt_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'receipt_processing_screen.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;

  // Subtle pulse animation for the centre icon
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Image picking
  // -------------------------------------------------------------------------

  Future<void> _pick(ImageSourceType src) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final File? image = src == ImageSourceType.camera
          ? await ReceiptService.pickFromCamera()
          : await ReceiptService.pickFromGallery();

      if (image == null) return; // User cancelled

      Get.to(
        () => ReceiptProcessingScreen(imageFile: image),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 400),
      );
    } catch (e) {
      _showError('Could not access image: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    Get.snackbar(
      'Error',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFFF3B30),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
            _buildActionButtons(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C28),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFF6C63FF),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Receipt Scanner',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Powered by Gemini AI',
                style: TextStyle(
                  color: const Color(0xFF6C63FF),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated receipt icon
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1C1C28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.25),
                    blurRadius: 48,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF6C63FF).withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.document_scanner_rounded,
                    size: 56,
                    color: Color(0xFF6C63FF),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            'Scan or Upload a Receipt',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Capture your bill or pick one from your gallery. '
              'Gemini AI will extract all the details instantly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF8E8E9E),
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 48),
          // Feature chips
          _buildFeatureRow(),
        ],
      ),
    );
  }

  Widget _buildFeatureRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _chip(Icons.flash_on_rounded, 'Instant'),
        const SizedBox(width: 10),
        _chip(Icons.security_rounded, 'Private'),
        const SizedBox(width: 10),
        _chip(Icons.save_alt_rounded, 'Saved Locally'),
      ],
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E2E3E), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF6C63FF)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8E8E9E),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Primary — Scan
          _ActionButton(
            label: 'Scan Receipt',
            icon: Icons.camera_alt_rounded,
            isPrimary: true,
            isLoading: _isLoading,
            onTap: () => _pick(ImageSourceType.camera),
          ),
          const SizedBox(height: 12),
          // Secondary — Upload
          _ActionButton(
            label: 'Upload Receipt',
            icon: Icons.photo_library_rounded,
            isPrimary: false,
            isLoading: _isLoading,
            onTap: () => _pick(ImageSourceType.gallery),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable action button
// ---------------------------------------------------------------------------

enum ImageSourceType { camera, gallery }

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: isPrimary ? const Color(0xFF6C63FF) : const Color(0xFF1C1C28),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: isPrimary
                ? null
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF2E2E3E),
                      width: 1.5,
                    ),
                  ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isPrimary ? Colors.white : const Color(0xFF8E8E9E),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: isPrimary ? Colors.white : const Color(0xFF8E8E9E),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
