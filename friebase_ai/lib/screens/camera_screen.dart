import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/receipt_provider.dart';
import '../widgets/loading_widget.dart';
import 'result_screen.dart';

class CameraScreen extends ConsumerStatefulWidget {
  final ImageSource source;

  const CameraScreen({super.key, required this.source});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  File? _imageFile;
  bool _isPicking = true;

  @override
  void initState() {
    super.initState();
    _pickImage();
  }

  Future<void> _pickImage() async {
    final pickerService = ref.read(imagePickerProvider);
    File? pickedFile;
    if (widget.source == ImageSource.camera) {
      pickedFile = await pickerService.captureImageFromCamera();
    } else {
      pickedFile = await pickerService.pickImageFromGallery();
    }

    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
        _isPicking = false;
      });
    } else {
      if (mounted) Navigator.pop(context); // User canceled
    }
  }

  void _analyzeImage() async {
    if (_imageFile == null) return;

    // Clear previous state before analyzing
    ref.read(scannedReceiptProvider.notifier).clear();

    // Navigate to result screen which will handle loading and displaying
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(imageFile: _imageFile!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CONFIRM IMAGE',
          style: TextStyle(fontFamily: 'monospace', letterSpacing: 2.0),
        ),
      ),
      body: _isPicking
          ? const LoadingWidget(message: 'INITIALIZING CAMERA...')
          : _imageFile == null
          ? const Center(
              child: Text(
                'NO IMAGE SELECTED.',
                style: TextStyle(fontFamily: 'monospace'),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(_imageFile!, fit: BoxFit.contain),
                        // Corners overlay for scanner feel
                        Positioned(
                          top: 0,
                          left: 0,
                          child: _buildCorner(top: true, left: true),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: _buildCorner(top: true, left: false),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: _buildCorner(top: false, left: true),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: _buildCorner(top: false, left: false),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.document_scanner,
                        color: Colors.black,
                        size: 28,
                      ),
                      label: const Text(
                        'BEGIN EXTRACTION',
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'monospace',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF00E5FF,
                        ), // AppConstants.primaryColor
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _analyzeImage,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCorner({required bool top, required bool left}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: top
              ? const BorderSide(color: Color(0xFF00E5FF), width: 4)
              : BorderSide.none,
          bottom: !top
              ? const BorderSide(color: Color(0xFF00E5FF), width: 4)
              : BorderSide.none,
          left: left
              ? const BorderSide(color: Color(0xFF00E5FF), width: 4)
              : BorderSide.none,
          right: !left
              ? const BorderSide(color: Color(0xFF00E5FF), width: 4)
              : BorderSide.none,
        ),
      ),
    );
  }
}
