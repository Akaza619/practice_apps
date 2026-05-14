import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ScannerOverlayWidget extends StatefulWidget {
  final File imageFile;

  const ScannerOverlayWidget({super.key, required this.imageFile});

  @override
  State<ScannerOverlayWidget> createState() => _ScannerOverlayWidgetState();
}

class _ScannerOverlayWidgetState extends State<ScannerOverlayWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image
        Image.file(
          widget.imageFile,
          fit: BoxFit.contain,
          color: Colors.black.withOpacity(0.4),
          colorBlendMode: BlendMode.darken,
        ),
        // Scanner Line
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Align(
              alignment: FractionalOffset(0.5, _animation.value),
              child: Container(
                height: 4.0,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.primaryColor.withOpacity(0.8),
                      blurRadius: 15.0,
                      spreadRadius: 5.0,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        // Overlay Text
        const Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Text(
                'OCR IN PROGRESS',
                style: TextStyle(
                  color: AppConstants.primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4.0,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Extracting data from receipt...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
