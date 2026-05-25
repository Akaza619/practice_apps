import 'dart:io';
import 'package:ai_logic_firebase/model/receipt_model.dart';
import 'package:ai_logic_firebase/service/receipt_service.dart';
import 'package:ai_logic_firebase/widgets/animated_dots_loader.dart';
import 'package:ai_logic_firebase/widgets/app_buttons.dart';
import 'package:ai_logic_firebase/widgets/receipt_header_card.dart';
import 'package:ai_logic_firebase/widgets/receipt_items_table.dart';
import 'package:ai_logic_firebase/widgets/receipt_summary_card.dart';
import 'package:ai_logic_firebase/widgets/status_badge.dart';
import 'package:ai_logic_firebase/widgets/view_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReceiptProcessingScreen extends StatefulWidget {
  final File imageFile;

  const ReceiptProcessingScreen({super.key, required this.imageFile});

  @override
  State<ReceiptProcessingScreen> createState() =>
      _ReceiptProcessingScreenState();
}

class _ReceiptProcessingScreenState extends State<ReceiptProcessingScreen>
    with TickerProviderStateMixin {
  ViewState _viewState = ViewState.loading;
  ReceiptModel? _receipt;
  String? _errorMessage;
  bool _isProcessing = false;

  late final AnimationController _dotCtrl;
  late final AnimationController _shimmerCtrl;
  late final Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();

    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _shimmerAnim = Tween<double>(
      begin: -1.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    _processReceipt();
  }

  @override
  void dispose() {
    _dotCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Future<void> _processReceipt() async {
    if (_isProcessing) return;
    _isProcessing = true;
    try {
      final result = await ReceiptService.processReceipt(widget.imageFile);
      if (!mounted) return;
      setState(() {
        _receipt = result;
        _viewState = ViewState.success;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _viewState = ViewState.error;
      });
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: _buildAppBar(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildImageCard()),
          SliverToBoxAdapter(child: const SizedBox(height: 20)),
          if (_viewState == ViewState.loading)
            SliverToBoxAdapter(child: _buildLoadingState())
          else if (_viewState == ViewState.error)
            SliverToBoxAdapter(child: _buildErrorState())
          else if (_viewState == ViewState.success && _receipt != null)
            SliverToBoxAdapter(child: _buildReceiptTable(_receipt!))
          else
            SliverToBoxAdapter(child: _buildEmptyState()),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0A0A0F),
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C28),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
        onPressed: () => Get.back(),
      ),
      title: const Text(
        'Processing Receipt',
        style: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        if (_viewState == ViewState.success)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2E1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2E5E2E), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF34C759),
                    size: 14,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Saved',
                    style: TextStyle(
                      color: Color(0xFF34C759),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: SizedBox(
                width: double.infinity,
                child: Image.file(
                  widget.imageFile,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 200,
                    color: const Color(0xFF1C1C28),
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: Color(0xFF4A4A5A),
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF0A0A0F).withOpacity(0.6),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: StatusBadge(state: _viewState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildProcessingCard(),
          const SizedBox(height: 20),
          _buildShimmerBlock(height: 52),
          const SizedBox(height: 12),
          _buildShimmerBlock(height: 36),
          const SizedBox(height: 12),
          _buildShimmerBlock(height: 36),
          const SizedBox(height: 12),
          _buildShimmerBlock(height: 36),
          const SizedBox(height: 12),
          _buildShimmerBlock(height: 52),
        ],
      ),
    );
  }

  Widget _buildProcessingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6C63FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          AnimatedDotsLoader(controller: _dotCtrl),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Gemini is analysing your receipt',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Extracting items, totals, taxes…',
                  style: TextStyle(color: Color(0xFF8E8E9E), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBlock({required double height}) {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (_, _) {
        return Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + _shimmerAnim.value, -0.5),
              end: Alignment(1.5 + _shimmerAnim.value, 0.5),
              colors: const [
                Color(0xFF1C1C28),
                Color(0xFF2A2A38),
                Color(0xFF1C1C28),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C28),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFF3B30).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFFF3B30),
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Processing Failed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8E8E9E), fontSize: 13),
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppOutlineButton(
                    label: 'Go Back',
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Get.back(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppFilledButton(
                    label: 'Retry',
                    icon: Icons.refresh_rounded,
                    onTap: () {
                      setState(() {
                        _viewState = ViewState.loading;
                        _errorMessage = null;
                      });
                      _processReceipt();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: Text(
          'No data found.',
          style: TextStyle(color: Color(0xFF8E8E9E), fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildReceiptTable(ReceiptModel receipt) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Receipt Details'),
          const SizedBox(height: 12),
          ReceiptHeaderCard(receipt: receipt),
          const SizedBox(height: 20),
          _sectionTitle('Items'),
          const SizedBox(height: 12),
          ReceiptItemsTable(items: receipt.items),
          const SizedBox(height: 20),
          _sectionTitle('Summary'),
          const SizedBox(height: 12),
          ReceiptSummaryCard(receipt: receipt),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF8E8E9E),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
