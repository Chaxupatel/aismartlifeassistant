import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// A premium, glossy button with a sleek linear gradient, Specular shine overlay,
/// press feedback, and drop shadows matching the application's upgraded aesthetic.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;
  final Gradient? gradient;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 54.0,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final resolvedGradient = gradient ?? AppColors.primaryGradient;
    final isButtonEnabled = onPressed != null && !isLoading;
    final double radius = AppSizes.radiusM + 4; // Capsule rounded style

    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: isButtonEnabled ? resolvedGradient : null,
        color: isButtonEnabled ? null : (isDark ? Colors.white10 : Colors.black12),
        boxShadow: isButtonEnabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(isDark ? 0.45 : 0.28),
                  blurRadius: 20,
                  spreadRadius: -2,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            // Diagonal shine specular highlight overlay
            if (isButtonEnabled)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x3BFFFFFF), // Specular glow shine
                          Color(0x00FFFFFF), // Fade out
                        ],
                        stops: [0.0, 0.45],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Interaction layer
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isButtonEnabled ? onPressed : null,
                borderRadius: BorderRadius.circular(radius),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (icon != null) ...[
                              Icon(icon, color: Colors.white, size: AppSizes.iconM),
                              const SizedBox(width: AppSizes.s),
                            ],
                            Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
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
