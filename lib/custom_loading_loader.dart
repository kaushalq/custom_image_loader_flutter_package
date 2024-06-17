import 'package:flutter/material.dart';

class CustomLoadingIndicator extends StatefulWidget {
  final double size;
  final Color loaderColor;
  final Duration duration;
  final ImageProvider image;

  const CustomLoadingIndicator({
    Key? key,
    required this.image,
    this.size = 100.0,
    this.loaderColor = Colors.blue,
    this.duration = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  _CustomLoadingIndicatorState createState() => _CustomLoadingIndicatorState();
}

class _CustomLoadingIndicatorState extends State<CustomLoadingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      reverseDuration: widget.duration,
      vsync: this,
    )..repeat();
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
              width: widget.size,
              height: widget.size,
              child: Padding(
                padding: const EdgeInsets.all(22.0),
                child: Image(image: widget.image),
              )),
          Positioned.fill(
            child: RotationTransition(
              turns: _animation,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: widget.size / 6,
                  height: widget.size / 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.loaderColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
