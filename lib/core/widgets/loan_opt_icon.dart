import 'package:flutter/material.dart';

/// A modern Material 3 monochrome circular icon embodying loan optimization.
///
/// Features a dark obsidian disc, dual metallic concentric rims, and a precision
/// architectural financial facade with a central upward optimization trajectory arrow,
/// diamond delta spark, and dual-tier foundation plinth.
///
/// Scales losslessly from small in-app headers (24–28px) to large launcher icons (512px).
class LoanOptAppIcon extends StatelessWidget {
  /// Diameter of the circular icon. Defaults to 28.0.
  final double size;

  /// Optional custom border width. If null, computed proportionally from [size].
  final double? borderWidth;

  /// Whether to render the outer slate border rim. Defaults to true.
  final bool showBorder;

  /// Optional override for the background gradient.
  final Color? backgroundColor;

  /// Optional override for primary glyph elements.
  final Color? foregroundColor;

  /// Accessibility label. Defaults to 'LoanOpt'.
  final String? semanticLabel;

  const LoanOptAppIcon({
    super.key,
    this.size = 28.0,
    this.borderWidth,
    this.showBorder = true,
    this.backgroundColor,
    this.foregroundColor,
    this.semanticLabel = 'LoanOpt',
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          size: Size(size, size),
          painter: LoanOptMonochromePainter(
            borderWidth: borderWidth,
            showBorder: showBorder,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the LoanOpt modern Material monochrome circular emblem.
class LoanOptMonochromePainter extends CustomPainter {
  final double? borderWidth;
  final bool showBorder;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const LoanOptMonochromePainter({
    this.borderWidth,
    this.showBorder = true,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final center = Offset(s / 2, s / 2);
    final r = s / 2;

    // 1. Dark obsidian background with radial gradient
    final bgPaint = Paint();
    if (backgroundColor != null) {
      bgPaint.color = backgroundColor!;
    } else {
      bgPaint.shader = RadialGradient(
        center: const Alignment(0.0, -0.2),
        radius: 1.05,
        colors: const [
          Color(0xFF1E283A), // Slate 800
          Color(0xFF0F172A), // Slate 900
          Color(0xFF050811), // Deep Obsidian
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    }
    canvas.drawCircle(center, r, bgPaint);

    // 2. Concentric outer rim
    final effectiveBorderWidth = borderWidth ?? (s * 0.035).clamp(1.0, 16.0);
    if (showBorder) {
      final outerRimPaint = Paint()
        ..color = const Color(0xFF334155) // Slate 700
        ..style = PaintingStyle.stroke
        ..strokeWidth = effectiveBorderWidth;
      canvas.drawCircle(center, (r - effectiveBorderWidth / 2).clamp(0.0, r), outerRimPaint);
    }

    // 3. Inner hairline ring (visible on larger sizes)
    if (s >= 32.0) {
      final innerRingPaint = Paint()
        ..color = const Color(0x3394A3B8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (s * 0.012).clamp(0.5, 4.0);
      canvas.drawCircle(center, r * 0.88, innerRingPaint);
    }

    // 4. Monochrome tonal palettes
    final white = foregroundColor ?? const Color(0xFFFFFFFF);
    final silver = foregroundColor != null
        ? foregroundColor!.withValues(alpha: 0.8)
        : const Color(0xFFCBD5E1); // Slate 300
    final tympanumColor = backgroundColor ?? const Color(0xFF0C1322);

    final whitePaint = Paint()
      ..color = white
      ..style = PaintingStyle.fill;

    final silverPaint = Paint()
      ..color = silver
      ..style = PaintingStyle.fill;

    final tympanumPaint = Paint()
      ..color = tympanumColor
      ..style = PaintingStyle.fill;

    // 5. Roof / Pediment
    final roofPath = Path()
      ..moveTo(center.dx, center.dy - r * 0.54)
      ..lineTo(center.dx + r * 0.54, center.dy - r * 0.22)
      ..lineTo(center.dx - r * 0.54, center.dy - r * 0.22)
      ..close();
    canvas.drawPath(roofPath, whitePaint);

    // Inner pediment dark cutout (tympanum)
    final tympanumPath = Path()
      ..moveTo(center.dx, center.dy - r * 0.45)
      ..lineTo(center.dx + r * 0.40, center.dy - r * 0.24)
      ..lineTo(center.dx - r * 0.40, center.dy - r * 0.24)
      ..close();
    canvas.drawPath(tympanumPath, tympanumPaint);

    // Delta / Optimization spark diamond in tympanum
    final sparkPath = Path()
      ..moveTo(center.dx, center.dy - r * 0.41)
      ..lineTo(center.dx + r * 0.08, center.dy - r * 0.33)
      ..lineTo(center.dx, center.dy - r * 0.25)
      ..lineTo(center.dx - r * 0.08, center.dy - r * 0.33)
      ..close();
    canvas.drawPath(sparkPath, whitePaint);

    // 6. Architrave (horizontal lintel beam)
    final beamRadius = (r * 0.03).clamp(0.5, 6.0);
    final beamRRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        center.dx - r * 0.54,
        center.dy - r * 0.17,
        center.dx + r * 0.54,
        center.dy - r * 0.09,
      ),
      Radius.circular(beamRadius),
    );
    canvas.drawRRect(beamRRect, whitePaint);

    // 7. Architectural Pillars (3 Columns)
    final pillarRadius = (r * 0.03).clamp(0.5, 6.0);

    // Left pillar (cool silver)
    final leftPillar = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        center.dx - r * 0.43,
        center.dy - r * 0.03,
        center.dx - r * 0.27,
        center.dy + r * 0.37,
      ),
      Radius.circular(pillarRadius),
    );
    canvas.drawRRect(leftPillar, silverPaint);

    // Center pillar (brilliant white with upward optimization arrow)
    final centerPath = Path()
      ..moveTo(center.dx, center.dy - r * 0.06)
      ..lineTo(center.dx + r * 0.11, center.dy + r * 0.04)
      ..lineTo(center.dx + r * 0.075, center.dy + r * 0.04)
      ..lineTo(center.dx + r * 0.075, center.dy + r * 0.37)
      ..lineTo(center.dx - r * 0.075, center.dy + r * 0.37)
      ..lineTo(center.dx - r * 0.075, center.dy + r * 0.04)
      ..lineTo(center.dx - r * 0.11, center.dy + r * 0.04)
      ..close();
    canvas.drawPath(centerPath, whitePaint);

    // Right pillar (cool silver)
    final rightPillar = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        center.dx + r * 0.27,
        center.dy - r * 0.03,
        center.dx + r * 0.43,
        center.dy + r * 0.37,
      ),
      Radius.circular(pillarRadius),
    );
    canvas.drawRRect(rightPillar, silverPaint);

    // 8. Dual-tier Plinth / Foundation
    final topPlinth = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        center.dx - r * 0.54,
        center.dy + r * 0.43,
        center.dx + r * 0.54,
        center.dy + r * 0.50,
      ),
      Radius.circular((r * 0.025).clamp(0.5, 5.0)),
    );
    canvas.drawRRect(topPlinth, silverPaint);

    final bottomPlinth = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        center.dx - r * 0.60,
        center.dy + r * 0.54,
        center.dx + r * 0.60,
        center.dy + r * 0.62,
      ),
      Radius.circular((r * 0.03).clamp(0.5, 6.0)),
    );
    canvas.drawRRect(bottomPlinth, whitePaint);
  }

  @override
  bool shouldRepaint(covariant LoanOptMonochromePainter oldDelegate) {
    return oldDelegate.borderWidth != borderWidth ||
        oldDelegate.showBorder != showBorder ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.foregroundColor != foregroundColor;
  }
}
