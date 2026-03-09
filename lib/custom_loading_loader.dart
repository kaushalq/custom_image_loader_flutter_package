/// A highly customizable Flutter loading indicator that orbits a dot (or custom widget)
/// around a central image.
library custom_loading_loader;

import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────

/// The shape of the orbiting indicator dot.
enum OrbiterShape { circle, square, diamond, star }

/// The animation curve preset for the orbit.
enum OrbitCurve { linear, easeInOut, elastic, bounce }

// ─────────────────────────────────────────────
// OrbiterConfig
// ─────────────────────────────────────────────

/// Configuration for a single orbiting dot.
class OrbiterConfig {
  /// Color of the dot. Defaults to [Colors.blue].
  final Color color;

  /// Diameter of the dot in logical pixels. Defaults to `16`.
  final double size;

  /// Shape of the dot. Defaults to [OrbiterShape.circle].
  final OrbiterShape shape;

  /// Phase offset in `[0, 1)` – use this to space multiple orbiters.
  ///
  /// Example – two dots 180° apart:
  /// ```dart
  /// orbiters: [OrbiterConfig(), OrbiterConfig(phaseOffset: 0.5)]
  /// ```
  final double phaseOffset;

  /// Optional drop-shadow applied beneath the dot.
  final List<BoxShadow>? shadows;

  /// Fully custom widget to render instead of the built-in painted shape.
  /// When set, [color], [size], [shape], and [shadows] are ignored.
  final Widget? child;

  const OrbiterConfig({
    this.color = Colors.blue,
    this.size = 16.0,
    this.shape = OrbiterShape.circle,
    this.phaseOffset = 0.0,
    this.shadows,
    this.child,
  });
}

// ─────────────────────────────────────────────
// CustomLoadingIndicator
// ─────────────────────────────────────────────

/// A loading indicator that renders [image] at the center and animates
/// one or more orbiting dots around it.
///
/// ```dart
/// CustomLoadingIndicator(
///   image: AssetImage('assets/logo.png'),
///   size: 120,
///   orbiters: [
///     OrbiterConfig(color: Colors.blue, size: 14),
///     OrbiterConfig(color: Colors.red,  size: 10, phaseOffset: 0.5),
///   ],
///   showOrbitTrack: true,
///   pulseImage: true,
/// )
/// ```
class CustomLoadingIndicator extends StatefulWidget {
  // ── Image ──────────────────────────────────

  /// The image displayed at the center.
  final ImageProvider image;

  /// Padding around the image inside the widget bounds.
  final EdgeInsets imagePadding;

  /// How the image fits its allocated space.
  final BoxFit imageFit;

  /// Clips the image with this border radius (e.g. circular avatar).
  final BorderRadius? imageRadius;

  /// Background decoration painted behind the image.
  final BoxDecoration? imageDecoration;

  // ── Sizing ─────────────────────────────────

  /// Width and height of the entire widget. Defaults to `100`.
  final double size;

  // ── Orbiters ───────────────────────────────

  /// One or more orbiting dot configurations.
  /// Omit to use a single blue circle.
  final List<OrbiterConfig> orbiters;

  /// Orbit radius as a fraction of `size / 2`.
  /// `1.0` = outer edge, `0.5` = halfway in. Defaults to `0.85`.
  final double orbitRadiusFactor;

  // ── Animation ──────────────────────────────

  /// Duration of one full orbit. Defaults to 2 s.
  final Duration duration;

  /// `true` for clockwise rotation (default), `false` for counter-clockwise.
  final bool clockwise;

  /// Easing applied to the rotation animation.
  final OrbitCurve orbitCurve;

  // ── Orbit track ────────────────────────────

  /// Draws a faint circular guide rail when `true`.
  final bool showOrbitTrack;

  /// Color of the orbit track. Defaults to `Colors.grey` at 20% opacity.
  final Color? orbitTrackColor;

  /// Stroke width of the orbit track. Defaults to `1`.
  final double orbitTrackWidth;

  // ── Pulse ──────────────────────────────────

  /// Adds a gentle scale-pulse to the central image.
  final bool pulseImage;

  /// Maximum scale factor during the pulse. `1.0` = no pulse. Defaults to `1.08`.
  final double pulseScale;

  // ── Control ────────────────────────────────

  /// Pause/resume the animation without removing the widget from the tree.
  final bool paused;

  // ── Callbacks ──────────────────────────────

  /// Fired once per completed orbit cycle.
  final VoidCallback? onCycleComplete;

  const CustomLoadingIndicator({
    super.key,
    required this.image,
    this.size = 100.0,
    this.imagePadding = const EdgeInsets.all(20),
    this.imageFit = BoxFit.contain,
    this.imageRadius,
    this.imageDecoration,
    this.orbiters = const [OrbiterConfig()],
    this.orbitRadiusFactor = 0.85,
    this.duration = const Duration(seconds: 2),
    this.clockwise = true,
    this.orbitCurve = OrbitCurve.linear,
    this.showOrbitTrack = false,
    this.orbitTrackColor,
    this.orbitTrackWidth = 1.0,
    this.pulseImage = false,
    this.pulseScale = 1.08,
    this.paused = false,
    this.onCycleComplete,
  });

  @override
  State<CustomLoadingIndicator> createState() => _CustomLoadingIndicatorState();
}

class _CustomLoadingIndicatorState extends State<CustomLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener(_onStatus);

    _rotationAnim = CurvedAnimation(
      parent: _controller,
      curve: _resolveCurve(widget.orbitCurve),
    );

    _pulseAnim = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: widget.pulseScale), weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: widget.pulseScale, end: 1.0), weight: 1),
    ]).animate(_controller);

    if (!widget.paused) _controller.repeat();
  }

  @override
  void didUpdateWidget(CustomLoadingIndicator old) {
    super.didUpdateWidget(old);
    if (old.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (widget.paused && _controller.isAnimating) {
      _controller.stop();
    } else if (!widget.paused && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onCycleComplete?.call();
    }
  }

  Curve _resolveCurve(OrbitCurve c) => switch (c) {
        OrbitCurve.linear => Curves.linear,
        OrbitCurve.easeInOut => Curves.easeInOut,
        OrbitCurve.elastic => Curves.elasticInOut,
        OrbitCurve.bounce => Curves.bounceInOut,
      };

  @override
  Widget build(BuildContext context) {
    final double radius = (widget.size / 2) * widget.orbitRadiusFactor;

    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => CustomPaint(
          painter: _OrbitTrackPainter(
            show: widget.showOrbitTrack,
            radius: radius,
            color: widget.orbitTrackColor ?? Colors.grey.withValues(alpha: 0.2),
            strokeWidth: widget.orbitTrackWidth,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Central image with optional pulse
              Transform.scale(
                scale: widget.pulseImage ? _pulseAnim.value : 1.0,
                child: _buildImage(),
              ),
              // Orbiters
              for (final cfg in widget.orbiters) _buildOrbiter(cfg, radius),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    Widget img = Image(image: widget.image, fit: widget.imageFit);

    if (widget.imageRadius != null) {
      img = ClipRRect(borderRadius: widget.imageRadius!, child: img);
    }

    return Container(
      width: widget.size,
      height: widget.size,
      padding: widget.imagePadding,
      decoration: widget.imageDecoration,
      child: img,
    );
  }

  Widget _buildOrbiter(OrbiterConfig cfg, double radius) {
    final double t = (_rotationAnim.value + cfg.phaseOffset) % 1.0;
    final double angle =
        (widget.clockwise ? 1 : -1) * 2 * math.pi * t - math.pi / 2;

    final double cx = math.cos(angle) * radius;
    final double cy = math.sin(angle) * radius;

    return Positioned(
      left: widget.size / 2 + cx - cfg.size / 2,
      top: widget.size / 2 + cy - cfg.size / 2,
      child: cfg.child ?? _DefaultOrbiter(config: cfg),
    );
  }
}

// ─────────────────────────────────────────────
// _DefaultOrbiter
// ─────────────────────────────────────────────

class _DefaultOrbiter extends StatelessWidget {
  final OrbiterConfig config;
  const _DefaultOrbiter({required this.config});

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: config.size,
        child: CustomPaint(painter: _OrbiterPainter(config: config)),
      );
}

class _OrbiterPainter extends CustomPainter {
  final OrbiterConfig config;
  const _OrbiterPainter({required this.config});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Shadows
    if (config.shadows != null) {
      for (final s in config.shadows!) {
        final sp = Paint()
          ..color = s.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.blurRadius);
        _drawShape(
          canvas,
          sp,
          Offset(center.dx + s.offset.dx, center.dy + s.offset.dy),
          r,
        );
      }
    }

    _drawShape(canvas, Paint()..color = config.color, center, r);
  }

  void _drawShape(Canvas canvas, Paint paint, Offset center, double r) {
    switch (config.shape) {
      case OrbiterShape.circle:
        canvas.drawCircle(center, r, paint);
      case OrbiterShape.square:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: r * 2, height: r * 2),
            const Radius.circular(3),
          ),
          paint,
        );
      case OrbiterShape.diamond:
        canvas.drawPath(
          Path()
            ..moveTo(center.dx, center.dy - r)
            ..lineTo(center.dx + r, center.dy)
            ..lineTo(center.dx, center.dy + r)
            ..lineTo(center.dx - r, center.dy)
            ..close(),
          paint,
        );
      case OrbiterShape.star:
        canvas.drawPath(_starPath(center, r, 5), paint);
    }
  }

  Path _starPath(Offset center, double outerR, int points) {
    final innerR = outerR * 0.4;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final angle = (math.pi / points) * i - math.pi / 2;
      final r = i.isEven ? outerR : innerR;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_OrbiterPainter old) =>
      old.config.color != config.color ||
      old.config.shape != config.shape ||
      old.config.size != config.size;
}

// ─────────────────────────────────────────────
// _OrbitTrackPainter
// ─────────────────────────────────────────────

class _OrbitTrackPainter extends CustomPainter {
  final bool show;
  final double radius;
  final Color color;
  final double strokeWidth;

  const _OrbitTrackPainter({
    required this.show,
    required this.radius,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!show) return;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(_OrbitTrackPainter old) =>
      old.show != show ||
      old.radius != radius ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}
