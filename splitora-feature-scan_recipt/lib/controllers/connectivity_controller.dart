import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class ConnectivityController extends GetxController with WidgetsBindingObserver {
  static ConnectivityController get instance => Get.find();

  final Connectivity _connectivity = Connectivity();
  final RxBool isConnected = true.obs;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isDialogShowing = false;
  int _lastCheckVersion = 0;
  Timer? _pollTimer;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _initConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  Future<void> _onAppResumed() async {
    final results = await _connectivity.checkConnectivity();
    await _updateConnectionStatus(results);
  }

  Future<void> _initConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    await _updateConnectionStatus(results);
  }

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    await _updateConnectionStatus(results);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    final version = ++_lastCheckVersion;

    final hasNetwork = results.any(
      (r) => [
        ConnectivityResult.wifi,
        ConnectivityResult.mobile,
        ConnectivityResult.ethernet,
      ].contains(r),
    );

    if (hasNetwork) {
      final hasInternet = await _hasInternetAccess();
      // Never discard a "connected" result — only discard stale "disconnected"
      if (!hasInternet && version != _lastCheckVersion) return;
      isConnected.value = hasInternet;
    } else {
      isConnected.value = false;
    }

    _syncDialogState();
    _handleDialog();
  }

  void _syncDialogState() {
    final isDialogOpen = Get.isDialogOpen ?? false;
    if (_isDialogShowing && !isDialogOpen) {
      _isDialogShowing = false;
    }
  }

  Future<bool> _hasInternetAccess() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _handleDialog() {
    if (isConnected.value) {
      if (_isDialogShowing) {
        _dismissNoInternetDialog();
      }
    } else {
      if (!_isDialogShowing) {
        _showNoInternetDialog();
      }
    }
  }

  void _showNoInternetDialog() {
    _isDialogShowing = true;
    _startPolling();
    Get.dialog(
      PopScope(
        canPop: false,
        child: _NoInternetDialog(
          onTurnOnInternet: _openNetworkSettings,
          onExit: _exitApp,
        ),
      ),
      barrierDismissible: false,
      useSafeArea: true,
    );
  }

  void _dismissNoInternetDialog() {
    _stopPolling();
    _isDialogShowing = false;
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (isConnected.value) return;
      _lastCheckVersion++;
      final hasInternet = await _hasInternetAccess();
      if (hasInternet) {
        isConnected.value = true;
        _syncDialogState();
        _handleDialog();
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _openNetworkSettings() async {
    if (Platform.isAndroid) {
      final uri = Uri.parse(
        'intent://settings/#Intent;action=android.settings.WIFI_SETTINGS;end',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } else if (Platform.isIOS) {
      final uri = Uri.parse('App-Prefs:root=WIFI');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    Get.snackbar(
      'Info',
      'Please enable internet from your device settings.',
      backgroundColor: Colors.blue.shade200,
    );
  }

  void _exitApp() {
    _stopPolling();
    _isDialogShowing = false;
    SystemNavigator.pop();
  }

  @override
  void onClose() {
    _stopPolling();
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.onClose();
  }
}

class _NoInternetDialog extends StatelessWidget {
  final VoidCallback onTurnOnInternet;
  final VoidCallback onExit;

  const _NoInternetDialog({
    required this.onTurnOnInternet,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'No Internet Connection',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'An active internet connection is required to use this app.\nPlease connect to the internet and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onTurnOnInternet,
                icon: const Icon(Icons.settings),
                label: const Text('Turn On Internet'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton.icon(
                onPressed: onExit,
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Exit App'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
