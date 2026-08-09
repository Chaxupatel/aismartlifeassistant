import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/connectivity_service.dart';
import 'glass_container.dart';

/// Premium glassmorphic Dialog shown when network connection is required.
class NoConnectionDialog extends StatefulWidget {
  final String message;

  const NoConnectionDialog({
    super.key,
    this.message = 'An active internet connection is required to use this feature.',
  });

  /// Helper static method to display the dialog
  static Future<bool> show(BuildContext context, {String? message}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => NoConnectionDialog(
        message: message ?? 'An active internet connection is required to use this feature.',
      ),
    );
    return result ?? false;
  }

  @override
  State<NoConnectionDialog> createState() => _NoConnectionDialogState();
}

class _NoConnectionDialogState extends State<NoConnectionDialog> {
  bool _isChecking = false;

  Future<void> _checkConnection() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
    });

    final isOffline = await ConnectivityService.instance.isOffline();

    setState(() {
      _isChecking = false;
    });

    if (!isOffline) {
      if (mounted) {
        Navigator.of(context).pop(true); // Return true (online)
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Still offline. Please check your network connection and try again.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false, // Prevent physical back button dismissal
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Dialog Main Body Card with high-contrast backing
              GlassContainer(
                borderRadius: 24,
                blur: 20,
                opacity: isDark ? 0.92 : 0.95,
                color: isDark ? const Color(0xFF161822) : Colors.white,
                borderColor: isDark ? Colors.white24 : Colors.black12,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    // Pulsing offline icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error.withOpacity(0.12),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        color: AppColors.error,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Connection Required',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.none,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Retry/Okay Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isChecking ? null : _checkConnection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isChecking
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Retry Connection',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              // Top-Right Close Button
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(false), // Return false (dismissed)
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white60 : Colors.black54,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
