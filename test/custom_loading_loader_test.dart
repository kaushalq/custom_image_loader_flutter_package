import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Enums ───────────────────────────────────
enum OrbiterShape { circle, square, diamond, star }
enum OrbitCurve { linear, easeInOut, elastic, bounce }

// ─── OrbiterConfig ───────────────────────────
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

// ─── CustomLoadingIndicator ──────────────────
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
    _rotationAnim = CurvedAnimation(parent: _controller, curve: _resolveCurve(widget.orbitCurve));
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
  void dispose() { _controller.dispose(); super.dispose(); }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) widget.onCycleComplete?.call();
  }

  Curve _resolveCurve(OrbitCurve c) => switch (c) {
    OrbitCurve.linear    => Curves.linear,
    OrbitCurve.easeInOut => Curves.easeInOut,
    OrbitCurve.elastic   => Curves.elasticInOut,
    OrbitCurve.bounce    => Curves.bounceInOut,
  };

  @override
  Widget build(BuildContext context) {
    final double radius = (widget.size / 2) * widget.orbitRadiusFactor;
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: widget.pulseImage ? _pulseAnim.value : 1.0,
              child: Container(
                width: widget.size,
                height: widget.size,
                padding: widget.imagePadding,
                decoration: widget.imageDecoration,
                child: Image(image: widget.image, fit: widget.imageFit),
              ),
            ),
            for (final cfg in widget.orbiters) _buildOrbiter(cfg, radius),
          ],
        ),
      ),
    );
  }

  Widget _buildOrbiter(OrbiterConfig cfg, double radius) {
    final double t = (_rotationAnim.value + cfg.phaseOffset) % 1.0;
    final double angle = (widget.clockwise ? 1 : -1) * 2 * math.pi * t - math.pi / 2;
    final double cx = math.cos(angle) * radius;
    final double cy = math.sin(angle) * radius;
    return Positioned(
      left: widget.size / 2 + cx - cfg.size / 2,
      top:  widget.size / 2 + cy - cfg.size / 2,
      child: cfg.child ?? SizedBox.square(
        dimension: cfg.size,
        child: CustomPaint(painter: _OrbiterPainter(config: cfg)),
      ),
    );
  }
}

class _OrbiterPainter extends CustomPainter {
  final OrbiterConfig config;
  const _OrbiterPainter({required this.config});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width / 2, Paint()..color = config.color);
  }

  @override
  bool shouldRepaint(_OrbiterPainter old) => old.config.color != config.color;
}

// ─────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────

void main() {
  // Use a 1x1 transparent PNG so Image doesn't throw in tests
  final image = MemoryImage(transparentPng);

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

  testWidgets('renders without error with defaults', (tester) async {
    await tester.pumpWidget(wrap(CustomLoadingIndicator(image: image)));
    expect(find.byType(CustomLoadingIndicator), findsOneWidget);
  });

  testWidgets('accepts custom size', (tester) async {
    await tester.pumpWidget(wrap(CustomLoadingIndicator(image: image, size: 200)));
    final box = tester.renderObject<RenderBox>(find.byType(SizedBox).first);
    expect(box.size.width, 200);
  });

  testWidgets('renders correct number of orbiters', (tester) async {
    await tester.pumpWidget(wrap(
      CustomLoadingIndicator(
        image: image,
        orbiters: const [
          OrbiterConfig(),
          OrbiterConfig(phaseOffset: 0.5),
          OrbiterConfig(phaseOffset: 0.25),
        ],
      ),
    ));
    expect(find.byType(CustomLoadingIndicator), findsOneWidget);
  });

  testWidgets('custom child orbiter renders correctly', (tester) async {
    await tester.pumpWidget(wrap(
      CustomLoadingIndicator(
        image: image,
        orbiters: const [OrbiterConfig(size: 20, child:  Icon(Icons.star, size: 20))],
      ),
    ));
    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  testWidgets('paused stops animation', (tester) async {
    await tester.pumpWidget(wrap(CustomLoadingIndicator(image: image, paused: true)));
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(CustomLoadingIndicator), findsOneWidget);
  });

  testWidgets('onCycleComplete fires', (tester) async {
    int calls = 0;
    await tester.pumpWidget(wrap(
      CustomLoadingIndicator(
        image: image,
        duration: const Duration(milliseconds: 100),
        onCycleComplete: () => calls++,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(calls, greaterThan(0));
  });
}

// Minimal valid 1×1 transparent PNG
final transparentPng = Uri.parse(
  'data:image/png;base64,'
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
).data!.contentAsBytes();
