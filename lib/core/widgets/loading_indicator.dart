import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'glass_container.dart';

/// A premium, glossy loading indicator component that matches the iOS design language.
/// Can be used inline or as an overlay.
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final bool isFullScreen;

  const LoadingIndicator({
    super.key,
    this.message,
    this.isFullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final indicator = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(24),
          blur: 20,
          opacity: isDark ? 0.12 : 0.2,
          borderRadius: 20,
          color: isDark ? Colors.black : Colors.white,
          borderColor: isDark ? Colors.white12 : Colors.black12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(
                radius: 16,
                color: AppColors.primary,
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    if (isFullScreen) {
      return Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: indicator,
        ),
      );
    }

    return Center(
      child: indicator,
    );
  }
}
