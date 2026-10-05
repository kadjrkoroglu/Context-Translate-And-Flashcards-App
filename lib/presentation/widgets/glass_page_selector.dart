import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:motor/motor.dart';

/// Live / AI / Basic selector. The bar stays still; pressing or dragging lifts
/// a clear glass lens over it (like the iOS tab bar). Under the lens only a
/// magnified copy of the bar shows, and the lens stretches with its speed.
class GlassPageSelector extends StatefulWidget {
  final PageController controller;
  final double Function() page;
  final List<String> labels;
  final ValueChanged<int> onSelected;

  const GlassPageSelector({
    super.key,
    required this.controller,
    required this.page,
    required this.labels,
    required this.onSelected,
  });

  @override
  State<GlassPageSelector> createState() => _GlassPageSelectorState();
}

class _GlassPageSelectorState extends State<GlassPageSelector> {
  static const double _width = 210;
  static const double _height = 36;
  static const double _inset = 2;
  static const double _lensOverflowX = 4;
  static const double _lensOverflowY = 7;
  static const double _magnify = 1.35;

  bool _isDown = false;
  double? _dragAlign;

  int get _last => widget.labels.length - 1;

  double get _segment => (_width - 2 * _inset) / widget.labels.length;

  double _alignFor(double page) => page / _last * 2 - 1;

  double _centerX(double align) =>
      _inset +
      _segment / 2 +
      (_width - 2 * _inset - _segment) * (align + 1) / 2;

  // Finger position → alignment (-1..1), with rubber-band past the ends.
  double _alignAt(Offset globalPosition) {
    final box = context.findRenderObject()! as RenderBox;
    final x = box.globalToLocal(globalPosition).dx;
    final segment = 1 / widget.labels.length;
    var t = ((x / box.size.width) - segment / 2) / (1 - segment);
    if (t < 0) t = -(-t * 0.4).clamp(0.0, 0.3);
    if (t > 1) t = 1 + ((t - 1) * 0.4).clamp(0.0, 0.3);
    return t * 2 - 1;
  }

  void _movePages(double align) {
    final position = widget.controller.hasClients
        ? widget.controller.position
        : null;
    if (position == null) return;
    final page = ((align + 1) / 2 * _last).clamp(0.0, _last.toDouble());
    position.jumpTo(page * position.viewportDimension);
  }

  void _onDown(DragDownDetails details) => setState(() => _isDown = true);

  void _onUpdate(DragUpdateDetails details) {
    final align = _alignAt(details.globalPosition);
    setState(() => _dragAlign = align);
    _movePages(align);
  }

  void _onEnd(DragEndDetails details) {
    final align = _dragAlign ?? _alignFor(widget.page());
    final box = context.findRenderObject()! as RenderBox;
    final velocity =
        details.velocity.pixelsPerSecond.dx / box.size.width * _last;
    // A quick flick goes one step further than where the finger let go.
    final projected = (align + 1) / 2 * _last + velocity * 0.15;
    final target = projected.round().clamp(0, _last);
    setState(() {
      _isDown = false;
      _dragAlign = null;
    });
    widget.onSelected(target);
  }

  void _onCancel() => setState(() {
    _isDown = false;
    _dragAlign = null;
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragDown: _onDown,
      onHorizontalDragUpdate: _onUpdate,
      onHorizontalDragEnd: _onEnd,
      onHorizontalDragCancel: _onCancel,
      child: SizedBox(
        width: _width,
        height: _height,
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) => _buildMotion(widget.page()),
        ),
      ),
    );
  }

  Widget _buildMotion(double page) {
    final moving = (page - page.round()).abs() > 0.05;
    return VelocityMotionBuilder<double>(
      converter: const SingleMotionConverter(),
      value: _dragAlign ?? _alignFor(page),
      motion: _dragAlign != null
          ? const Motion.interactiveSpring(snapToEnd: true)
          : const Motion.bouncySpring(snapToEnd: true),
      builder: (context, align, velocity, _) => SingleMotionBuilder(
        motion: const Motion.snappySpring(
          snapToEnd: true,
          duration: Duration(milliseconds: 300),
        ),
        value: _isDown || moving ? 1.0 : 0.0,
        builder: (context, lift, _) => SingleMotionBuilder(
          motion: const Motion.bouncySpring(
            duration: Duration(milliseconds: 600),
          ),
          value: velocity,
          // The springs overshoot a little past 0 and 1.
          builder: (context, wobble, _) =>
              _buildBar(page, align, lift.clamp(0.0, 1.0), wobble),
        ),
      ),
    );
  }

  Widget _buildBar(double page, double align, double lift, double wobble) {
    final cx = _centerX(align);
    // Wider along the motion (spans two items when fast), a bit flatter.
    final speed = (wobble.abs() / 10).clamp(0.0, 1.0);
    final lensW = (_segment + 2 * _lensOverflowX * lift) * (1 + speed * 0.6);
    final lensH =
        (_height - 2 * _inset + 2 * _lensOverflowY * lift) * (1 - speed * 0.15);
    final lens = Rect.fromCenter(
      center: Offset(cx, _height / 2),
      width: lensW,
      height: lensH,
    );
    final showLens = lift > 0;

    final bar = Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
        ),
        _restingPill(cx: cx, segment: _segment, opacity: 1 - lift),
        _Labels(labels: widget.labels, page: page, onTap: widget.onSelected),
      ],
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The real bar is cut out under the lens, so nothing shows twice.
        Positioned.fill(
          child: showLens
              ? ClipPath(clipper: _OutsideLens(lens), child: bar)
              : bar,
        ),
        if (showLens)
          Positioned.fromRect(
            rect: lens,
            child: IgnorePointer(
              child: _Lens(
                lens: lens,
                lift: lift,
                magnify: 1 + (_magnify - 1) * lift,
                labels: widget.labels,
                page: page,
                pillX: cx,
                segment: _segment,
              ),
            ),
          ),
      ],
    );
  }
}

Widget _restingPill({
  required double cx,
  required double segment,
  required double opacity,
}) {
  const inset = _GlassPageSelectorState._inset;
  return Positioned(
    left: cx - segment / 2,
    top: inset,
    width: segment,
    height: _GlassPageSelectorState._height - 2 * inset,
    child: Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
      ),
    ),
  );
}

class _OutsideLens extends CustomClipper<Path> {
  final Rect lens;

  const _OutsideLens(this.lens);

  @override
  Path getClip(Size size) => Path.combine(
    PathOperation.difference,
    Path()..addRect(Offset.zero & size),
    Path()..addRRect(
      RRect.fromRectAndRadius(lens, Radius.circular(lens.shortestSide / 2)),
    ),
  );

  @override
  bool shouldReclip(_OutsideLens oldClipper) => oldClipper.lens != lens;
}

class _Labels extends StatelessWidget {
  final List<String> labels;
  final double page;
  final ValueChanged<int>? onTap;

  /// 0..1 towards all-white (the lens copy brightens as the lens lifts).
  final double brighten;

  const _Labels({
    required this.labels,
    required this.page,
    this.onTap,
    this.brighten = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap == null ? null : () => onTap!(i),
              child: Center(
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color.lerp(
                      Color.lerp(
                        Colors.white.withValues(alpha: 0.5),
                        Colors.white,
                        (1 - (page - i).abs()).clamp(0.0, 1.0),
                      ),
                      Colors.white,
                      brighten,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Inside: the whole bar magnified around the lens centre. On top: clear glass
/// that glows and bends at the rim.
class _Lens extends StatelessWidget {
  final Rect lens;
  final double lift;
  final double magnify;
  final List<String> labels;
  final double page;
  final double pillX;
  final double segment;

  const _Lens({
    required this.lens,
    required this.lift,
    required this.magnify,
    required this.labels,
    required this.page,
    required this.pillX,
    required this.segment,
  });

  @override
  Widget build(BuildContext context) {
    const width = _GlassPageSelectorState._width;
    const height = _GlassPageSelectorState._height;
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(lens.shortestSide / 2),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -lens.left,
                top: -lens.top,
                width: width,
                height: height,
                child: Transform.scale(
                  scale: magnify,
                  origin: Offset(lens.center.dx - width / 2, 0),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      // Matches the bar at lift 0, so the lens fades out without a jump.
                      _restingPill(
                        cx: pillX,
                        segment: segment,
                        opacity: 1 - lift,
                      ),
                      _Labels(labels: labels, page: page, brighten: lift),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        LiquidGlass.withOwnLayer(
          settings: LiquidGlassSettings(
            visibility: lift,
            glassColor: const Color(0x00FFFFFF),
            thickness: 13,
            refractiveIndex: 1.15,
            chromaticAberration: 0.35,
            lightIntensity: 1.6,
            ambientStrength: 0.1,
            saturation: 1.2,
            blur: 0,
          ),
          shape: const LiquidRoundedSuperellipse(borderRadius: 64),
          child: const SizedBox.expand(),
        ),
      ],
    );
  }
}
