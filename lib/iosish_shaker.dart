/// A widget that allows you to shake your widgets,
/// just like the pin on iOS is shaked on incorrect input.
library iosish_shaker;

import 'package:flutter/widgets.dart';

/// Controller for the [Shaker].
class ShakerController {
  _ShakerState? _state;

  /// Shakes the child widget.
  ///
  /// The future completes when the shake animation is completed.
  Future<void> shake() {
    if (_state == null) {
      assert(false, 'Tried to shake w/o widget in place.');
      return Future.value();
    }

    return _state!._shake();
  }
}

/// A widget that can shake its child widget.
///
/// ### Example
///
/// ```dart
/// // Create a controller:
///  final controller = ShakerController();
///
/// // Use the shaker widget:
/// return Shaker(
///   controller: controller,
///   child: child,
/// );
///
/// // Shake, shake, shake!
/// await controller.shake();
///
/// // The future is released when the animation is completed.
/// // So you can perform some action right after if you want to.
/// ```
class Shaker extends StatefulWidget {
  final ShakerController controller;
  final Widget child;

  const Shaker({
    Key? key,
    required this.controller,
    required this.child,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ShakerState createState() => _ShakerState();
}

class _ShakerState extends State<Shaker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  bool _isAnimating = false;

  final int _shakeCount = 6;
  final double _maxOffset = 40.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
    )..value = .5;

    _animation = Tween<double>(
      begin: -_maxOffset,
      end: _maxOffset,
    ).animate(_controller);

    widget.controller._state = this;
  }

  @override
  void didUpdateWidget(covariant Shaker oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller._state = null;
      widget.controller._state = null;
    }
  }

  Duration _calculateDuration(int currentStep) {
    return Duration(milliseconds: 50 + currentStep * 10);
  }

  Future<void> _shake() async {
    if (_isAnimating) {
      return;
    }

    _isAnimating = true;

    var multipler = 1;
    var currentStep = 0;

    final max = _shakeCount;
    while (currentStep < max) {
      final reversedStep = (1.0 / (currentStep + 1));

      final curveToUse = currentStep == 0
          ? Curves.easeInOutSine
          : currentStep == max - 1
              ? Curves.easeInOutSine
              : Curves.easeInOutSine;

      final curvedPosition = curveToUse.transform(reversedStep);

      final shakeDuration = _calculateDuration(currentStep);

      if (!mounted) {
        return;
      }

      await _controller.animateTo(
        (.5 + curvedPosition * multipler).clamp(.0, 1.0),
        duration: shakeDuration,
        curve: currentStep == 0 ? Curves.easeInOutCirc : Curves.easeInOut,
      );

      multipler = -multipler;
      currentStep++;
    }

    final backToNormalDuration = _calculateDuration(currentStep + 1);

    if (!mounted) {
      return;
    }

    await _controller.animateTo(
      .5,
      duration: backToNormalDuration,
      curve: Curves.easeInOutSine,
    );

    _isAnimating = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.controller._state = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
