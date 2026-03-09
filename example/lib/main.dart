import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────

enum OrbiterShape { circle, square, diamond, star }

enum OrbitCurve { linear, easeInOut, elastic, bounce }

// ─────────────────────────────────────────────
// OrbiterConfig
// ─────────────────────────────────────────────

class OrbiterConfig {
  final Color color;
  final double size;
  final OrbiterShape shape;
  final double phaseOffset;
  final List<BoxShadow>? shadows;
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

class CustomLoadingIndicator extends StatefulWidget {
  final ImageProvider image;
  final EdgeInsets imagePadding;
  final BoxFit imageFit;
  final BorderRadius? imageRadius;
  final BoxDecoration? imageDecoration;
  final double size;
  final List<OrbiterConfig> orbiters;
  final double orbitRadiusFactor;
  final Duration duration;
  final bool clockwise;
  final OrbitCurve orbitCurve;
  final bool showOrbitTrack;
  final Color? orbitTrackColor;
  final double orbitTrackWidth;
  final bool pulseImage;
  final double pulseScale;
  final bool paused;
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
      TweenSequenceItem(tween: Tween(begin: 1.0, end: widget.pulseScale), weight: 1),
      TweenSequenceItem(tween: Tween(begin: widget.pulseScale, end: 1.0), weight: 1),
    ]).animate(_controller);

    if (!widget.paused) _controller.repeat();
  }

  @override
  void didUpdateWidget(CustomLoadingIndicator old) {
    super.didUpdateWidget(old);
    if (old.duration != widget.duration) _controller.duration = widget.duration;
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
    if (status == AnimationStatus.completed) widget.onCycleComplete?.call();
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
              Transform.scale(
                scale: widget.pulseImage ? _pulseAnim.value : 1.0,
                child: _buildImage(),
              ),
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
    final double angle = (widget.clockwise ? 1 : -1) * 2 * math.pi * t - math.pi / 2;
    final double cx = math.cos(angle) * radius;
    final double cy = math.sin(angle) * radius;

    return Positioned(
      left: widget.size / 2 + cx - cfg.size / 2,
      top: widget.size / 2 + cy - cfg.size / 2,
      child: cfg.child ?? _DefaultOrbiter(config: cfg),
    );
  }
}

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

    if (config.shadows != null) {
      for (final s in config.shadows!) {
        final sp = Paint()
          ..color = s.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.blurRadius);
        _drawShape(canvas, sp, Offset(center.dx + s.offset.dx, center.dy + s.offset.dy), r);
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
      old.show != show || old.radius != radius || old.color != color || old.strokeWidth != strokeWidth;
}

// ─────────────────────────────────────────────
// App
// ─────────────────────────────────────────────

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom Loading Loader — Examples',
      theme: ThemeData.dark(useMaterial3: true),
      home: const ExamplesPage(),
    );
  }
}

class ExamplesPage extends StatefulWidget {
  const ExamplesPage({super.key});

  @override
  State<ExamplesPage> createState() => _ExamplesPageState();
}

class _ExamplesPageState extends State<ExamplesPage> {
  bool _paused = false;

  @override
  Widget build(BuildContext context) {
    const image = AssetImage('assets/image.png');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Loading Loader'),
        actions: [
          IconButton(
            tooltip: _paused ? 'Resume' : 'Pause',
            icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
            onPressed: () => setState(() => _paused = !_paused),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section('Basic — single blue dot', [
              CustomLoadingIndicator(image: image, paused: _paused),
            ]),
            _section('Custom size, color & speed', [
              CustomLoadingIndicator(
                image: image,
                size: 80,
                orbiters: const [OrbiterConfig(color: Colors.orange, size: 12)],
                duration: const Duration(milliseconds: 800),
                paused: _paused,
              ),
              CustomLoadingIndicator(
                image: image,
                size: 140,
                orbiters: const [OrbiterConfig(color: Colors.teal, size: 20)],
                duration: const Duration(seconds: 3),
                paused: _paused,
              ),
            ]),
            _section('Multiple orbiters', [
              CustomLoadingIndicator(
                image: image,
                size: 120,
                showOrbitTrack: true,
                orbiters: const [
                  OrbiterConfig(color: Colors.red,   size: 13),
                  OrbiterConfig(color: Colors.green, size: 13, phaseOffset: 1 / 3),
                  OrbiterConfig(color: Colors.blue,  size: 13, phaseOffset: 2 / 3),
                ],
                paused: _paused,
              ),
              CustomLoadingIndicator(
                image: image,
                size: 110,
                orbiters: const [
                  OrbiterConfig(color: Colors.purple, size: 14),
                  OrbiterConfig(color: Colors.amber,  size: 14, phaseOffset: 0.5),
                ],
                duration: const Duration(milliseconds: 1400),
                paused: _paused,
              ),
            ]),
            _section('Orbiter shapes', [
              CustomLoadingIndicator(
                image: image,
                size: 110,
                orbiters: const [OrbiterConfig(shape: OrbiterShape.square,  color: Colors.cyan,   size: 14)],
                paused: _paused,
              ),
              CustomLoadingIndicator(
                image: image,
                size: 110,
                orbiters: const [OrbiterConfig(shape: OrbiterShape.diamond, color: Colors.pink,   size: 16)],
                paused: _paused,
              ),
              CustomLoadingIndicator(
                image: image,
                size: 110,
                orbiters: const [OrbiterConfig(shape: OrbiterShape.star,    color: Colors.yellow, size: 18)],
                paused: _paused,
              ),
            ]),
            _section('Orbit track, pulse & shadow', [
              CustomLoadingIndicator(
                image: image,
                size: 120,
                showOrbitTrack: true,
                orbitTrackColor: Colors.white24,
                orbitTrackWidth: 1.5,
                pulseImage: true,
                pulseScale: 1.1,
                orbiters: const [
                  OrbiterConfig(
                    color: Colors.lightBlueAccent,
                    size: 14,
                    shadows: [BoxShadow(color: Colors.lightBlueAccent, blurRadius: 8)],
                  ),
                ],
                paused: _paused,
              ),
            ]),
            _section('Counter-clockwise & easeInOut', [
              CustomLoadingIndicator(
                image: image,
                size: 110,
                clockwise: false,
                orbitCurve: OrbitCurve.easeInOut,
                orbiters: const [OrbiterConfig(color: Colors.deepOrange, size: 14)],
                paused: _paused,
              ),
            ]),
            _section('Circular clip + background', [
              CustomLoadingIndicator(
                image: image,
                size: 120,
                imagePadding: const EdgeInsets.all(14),
                imageRadius: BorderRadius.circular(60),
                imageDecoration: BoxDecoration(
                  color: Colors.white12,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                orbiters: const [
                  OrbiterConfig(color: Colors.greenAccent, size: 12),
                  OrbiterConfig(color: Colors.greenAccent, size: 8, phaseOffset: 0.5),
                ],
                showOrbitTrack: true,
                paused: _paused,
              ),
            ]),
            _section('Custom widget orbiter', [
              CustomLoadingIndicator(
                image: image,
                size: 120,
                orbiters: const[
                  OrbiterConfig(size: 18, phaseOffset: 0,   child:  Icon(Icons.star,     color: Colors.amber, size: 18)),
                  OrbiterConfig(size: 18, phaseOffset: 0.5, child:  Icon(Icons.favorite, color: Colors.red,   size: 18)),
                ],
                paused: _paused,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> widgets) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  letterSpacing: 0.5, color: Colors.white70)),
          const SizedBox(height: 16),
          Wrap(spacing: 32, runSpacing: 32,
              crossAxisAlignment: WrapCrossAlignment.center, children: widgets),
        ],
      ),
    );
  }
}
