import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';
import 'camera_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _navigateToCamera(BuildContext context, ImageSource source) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(source: source),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Scanner AI'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Tech Pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: GridPaper(
                color: AppConstants.primaryColor,
                interval: 50,
                divisions: 1,
                subdivisions: 1,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'SCAN RECEIPT',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8.0,
                    color: AppConstants.primaryColor,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () => _navigateToCamera(context, ImageSource.camera),
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppConstants.surfaceColor,
                      border: Border.all(color: AppConstants.primaryColor, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.primaryColor.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.document_scanner_outlined,
                        size: 80,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSecondaryAction(
                      context,
                      icon: Icons.photo_library_outlined,
                      label: 'GALLERY',
                      onTap: () => _navigateToCamera(context, ImageSource.gallery),
                    ),
                    _buildSecondaryAction(
                      context,
                      icon: Icons.history_outlined,
                      label: 'HISTORY',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HistoryScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryAction(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.white70),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
