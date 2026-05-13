// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/receipt.dart';
import '../services/gemini_receipt_service.dart';
import '../services/storage_service.dart';
import 'receipt_detail_screen.dart';

enum _ScanState { idle, processing, error }

class ScanScreen extends StatefulWidget {
  final StorageService storage;
  const ScanScreen({super.key, required this.storage});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _picker = ImagePicker();
  final _gemini = GeminiReceiptService();
  final _uuid = const Uuid();

  _ScanState _state = _ScanState.idle;
  String _statusMsg = '';
  String? _errorMsg;
  int _step = 0;

  // ── DOUBLE-TAP GUARD ──────────────────────────────────────────────────────
  // Prevents the user tapping Camera/Gallery twice quickly and firing two API
  // calls. Set to true the instant a tap is registered; cleared after the
  // entire flow finishes (success, error, or cancel).
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan receipt')),
      body: switch (_state) {
        _ScanState.processing => _ProcessingView(
          message: _statusMsg,
          step: _step,
        ),
        _ScanState.error => _ErrorView(
          message: _errorMsg ?? 'Something went wrong',
          onRetry: _reset,
        ),
        _ScanState.idle => _IdleView(
          // Pass guarded callbacks — ignored during processing
          onCamera: () => _capture(ImageSource.camera),
          onGallery: () => _capture(ImageSource.gallery),
        ),
      },
    );
  }

  // ── Reset (used by Try-again button) ──────────────────────────────────────
  // Only called when state == error, so _isProcessing is already false.
  void _reset() {
    if (_isProcessing) return; // safety
    setState(() {
      _state = _ScanState.idle;
      _errorMsg = null;
      _step = 0;
    });
  }

  // ── Main capture + scan flow ───────────────────────────────────────────────
  Future<void> _capture(ImageSource source) async {
    // ── Guard: ignore if already processing ───────────────────────────────────
    // This is the ONLY place _isProcessing is set to true.
    // It covers: double-tap, widget rebuild, navigation events.
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // ── Step 0: pick image (no API call yet) ──────────────────────────────
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 100,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 4096,
        maxHeight: 4096,
      );

      // User cancelled the picker — release lock and stay idle
      if (file == null) {
        _isProcessing = false;
        return;
      }

      // ── Step 1 + 2: update UI, then fire EXACTLY ONE API call ─────────────
      // Both step changes are combined into a single setState so Flutter
      // does one rebuild, not two, before the await below.
      if (!mounted) return;
      setState(() {
        _state = _ScanState.processing;
        _step = 2;
        _statusMsg = 'Sending to Gemini AI...';
      });

      // ── THE ONE AND ONLY API CALL ─────────────────────────────────────────
      // GeminiReceiptService._busy also guards against concurrent calls at
      // the service level (defence in depth).
      final result = await _gemini.analyzeReceipt(file.path);

      if (!mounted) return;

      // ── Handle error result ────────────────────────────────────────────────
      if (result.hasError) {
        setState(() {
          _state = _ScanState.error;
          _errorMsg = result.errorMessage;
        });
        return; // _isProcessing released in finally
      }

      // ── Handle empty result ────────────────────────────────────────────────
      if (result.rawText.isEmpty && result.items.isEmpty) {
        setState(() {
          _state = _ScanState.error;
          _errorMsg =
              'Gemini could not read text from this image.\n\n'
              'Tips:\n'
              '• Lay the receipt flat on a dark surface\n'
              '• Use bright, even lighting — avoid shadows & glare\n'
              '• Hold the phone directly above, not at an angle\n'
              '• Make sure the full receipt is in frame';
        });
        return;
      }

      // ── Step 3: build Receipt object (no API call) ─────────────────────────
      setState(() {
        _step = 3;
        _statusMsg = 'Finalising...';
      });

      final receipt = Receipt(
        id: _uuid.v4(),
        storeName: result.storeName,
        date: result.date ?? DateTime.now(),
        total: result.resolvedTotal,
        items: result.items,
        category: _gemini.suggestCategory(result.storeName),
        imagePath: file.path,
        rawText: result.rawText,
        scannedAt: DateTime.now(),
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptDetailScreen(
            receipt: receipt,
            storage: widget.storage,
            isNew: true,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _ScanState.error;
          _errorMsg = 'Unexpected error: ${e.toString()}';
        });
      }
    } finally {
      // ── ALWAYS release the lock ────────────────────────────────────────────
      // Whether success, error, or exception — the lock is released here.
      // GeminiReceiptService._busy is also released in its own finally block.
      _isProcessing = false;
    }
  }
}

// ─── Idle view ────────────────────────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  const _IdleView({required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Gemini badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: cs.onPrimaryContainer,
                ),
                const SizedBox(width: 6),
                Text(
                  'Powered by Gemini AI',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Icon(
            Icons.document_scanner,
            size: 96,
            color: cs.primary.withOpacity(.25),
          ),
          const SizedBox(height: 20),
          const Text(
            'Scan your receipt',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Gemini AI reads the image and extracts all items, '
            'prices and totals — even from blurry or angled photos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurface.withOpacity(.6)),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _OptionCard(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  subtitle: 'Take a new photo',
                  onTap: onCamera,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _OptionCard(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  subtitle: 'Choose existing',
                  onTap: onGallery,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            color: cs.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.tips_and_updates,
                    color: cs.onSecondaryContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Best results: lay the receipt flat on a dark surface, '
                      'use bright overhead lighting, hold the phone directly above.',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _OptionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          child: Column(
            children: [
              Icon(
                icon,
                size: 36,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Processing view ──────────────────────────────────────────────────────────

class _ProcessingView extends StatelessWidget {
  final String message;
  final int step;
  const _ProcessingView({required this.message, required this.step});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const steps = [
      (Icons.image_outlined, 'Preparing image'),
      (Icons.cloud_upload_outlined, 'Sending to Gemini'),
      (Icons.psychology_outlined, 'AI reading receipt'),
      (Icons.check_circle_outline, 'Finalising'),
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 28),
            Text(
              message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ...steps.asMap().entries.map((e) {
              final idx = e.key + 1;
              final (icon, label) = e.value;
              final done = step > idx;
              final active = step == idx;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: done
                            ? cs.primary
                            : active
                            ? cs.primaryContainer
                            : cs.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        done ? Icons.check : icon,
                        size: 15,
                        color: done
                            ? cs.onPrimary
                            : active
                            ? cs.onPrimaryContainer
                            : cs.onSurface.withOpacity(.35),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: active
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: active
                            ? cs.onSurface
                            : cs.onSurface.withOpacity(.4),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
            Text(
              'Usually takes 5–15 seconds',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withOpacity(.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: cs.error),
            const SizedBox(height: 16),
            const Text(
              'Scan failed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.errorContainer.withOpacity(.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withOpacity(.75),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Single try-again button — one tap = one new API call
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
