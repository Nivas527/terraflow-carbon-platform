import 'dart:ui';
import 'package:flutter/material.dart';

/// A premium glassmorphic UI container applying a frosted backdrop blur,
/// translucent borders, and double-layered linear background gradients.
class GlassContainer extends StatelessWidget {
  /// The widget content rendered inside the container.
  final Widget child;

  /// Optional absolute width.
  final double? width;

  /// Optional absolute height.
  final double? height;

  /// Inset padding around the child content (defaults to `24.0`).
  final EdgeInsetsGeometry? padding;

  /// Margin space around the exterior of the container.
  final EdgeInsetsGeometry? margin;

  /// Border radius curve magnitude (defaults to `16.0`).
  final double borderRadius;

  /// Custom linear background colors for the glass layer.
  final List<Color>? gradientColors;

  /// Border color outlining the container (defaults to low opacity white).
  final Color? borderColor;

  /// Instantiates a [GlassContainer].
  const GlassContainer({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 16.0,
    this.gradientColors,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Container(
            padding: padding ?? const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? Colors.white.withOpacity(0.1),
                width: 1.2,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors ?? [
                  Colors.white.withOpacity(0.07),
                  Colors.white.withOpacity(0.02),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
