import 'dart:ui';
import 'package:flutter/material.dart';

/// An upgraded, ultra-premium glassmorphic container inspired by iOS 26 design language.
/// It uses [BackdropFilter] for deep blur, is layered with a linear glass depth gradient,
/// and features an Ignored-Pointer specular shine overlay to simulate glass reflection.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color color;
  final Color borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.opacity = 0.08,
    this.color = Colors.white,
    this.borderColor = const Color(0x3BFFFFFF),
    this.borderRadius = 24.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.width,
    this.height,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      margin: margin,
      alignment: alignment,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          // Soft outer shadow for ambient depth
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.06),
            blurRadius: 32,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Stack(
            children: [
              // Translucent gradient backing
              Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: color.withOpacity(opacity),
                  borderRadius: BorderRadius.circular(borderRadius),
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(opacity + (isDark ? 0.05 : 0.15)),
                      color.withOpacity(opacity),
                      color.withOpacity(opacity * 0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: isDark ? const Color(0x22FFFFFF) : const Color(0x55FFFFFF),
                    width: 1.2,
                  ),
                ),
                child: child,
              ),
              // Diagonal specular glass reflection overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0x2BFFFFFF), // Specular light highlight
                          Color(0x00FFFFFF), // Fades to zero
                        ],
                        stops: [0.0, 0.4],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
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
