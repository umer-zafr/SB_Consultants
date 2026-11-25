import '../../../imports/imports.dart';

class RawToast extends StatefulWidget {
  final Widget child;
  final Duration animationDuration;
  final Duration snackbarDuration;
  final Curve? animationCurve;
  final bool autoDismiss;
  final ToastPosition toastPosition;
  final double Function() getscaleFactor;
  final double Function() getPosition;
  final void Function() onRemove;

  const RawToast({
    super.key,
    required this.child,
    required this.animationDuration,
    required this.toastPosition,
    required this.snackbarDuration,
    required this.onRemove,
    this.autoDismiss = true,
    required this.getPosition,
    this.animationCurve,
    required this.getscaleFactor,
  });

  @override
  State<RawToast> createState() => RawToastState();
}

class RawToastState extends State<RawToast> {
  final GlobalKey positionedKey = GlobalKey();
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    // Subtle tactile feedback on toast appearance
    HapticFeedback.lightImpact().ignore();
  }

  void _handleRemove() {
    if (_dismissed) return;
    _dismissed = true;
    widget.onRemove();
  }

  Widget getChildBasedOnDismiss(Widget child) {
    return Animate(
      onComplete: (controller) {
        if (widget.autoDismiss && !_dismissed) {
          _handleRemove();
        }
      },
      effects: [
        SlideEffect(
          begin: Offset(
            0,
            widget.toastPosition == ToastPosition.bottom ? 1.5 : -1.5,
          ),
          end: Offset.zero,
          duration: widget.animationDuration,
          curve: widget.animationCurve ?? Curves.easeOutCubic,
        ),
        FadeEffect(
          duration: Duration(milliseconds: (widget.animationDuration.inMilliseconds * 0.8).round()),
          begin: 0,
          end: 1,
        ),
        if (widget.autoDismiss)
          SlideEffect(
            delay: widget.snackbarDuration,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInCubic,
            begin: Offset.zero,
            end: Offset(
              0,
              widget.toastPosition == ToastPosition.bottom ? 1.5 : -1.5,
            ),
          ),
        if (widget.autoDismiss)
          FadeEffect(
            delay: widget.snackbarDuration,
            duration: const Duration(milliseconds: 250),
            begin: 1,
            end: 0,
          ),
      ],
      child: Dismissible(
        key: const ValueKey('raw_toast_dismissible'),
        direction: widget.toastPosition == ToastPosition.top
            ? DismissDirection.up
            : DismissDirection.down,
        onDismissed: (_) {
          HapticFeedback.selectionClick().ignore();
          _handleRemove();
        },
        child: widget.child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final safeTop = mediaQuery.padding.top;
    final safeBottom = mediaQuery.padding.bottom;

    return AnimatedPositioned(
      duration: Duration(
        milliseconds: widget.animationDuration.inMilliseconds,
      ),
      key: positionedKey,
      curve: Curves.easeOutCubic,
      top: widget.toastPosition == ToastPosition.top
          ? (safeTop + 12 + widget.getPosition())
          : null,
      bottom: widget.toastPosition == ToastPosition.bottom
          ? (safeBottom + 20 + widget.getPosition())
          : null,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: AnimatedScale(
          duration: widget.animationDuration,
          curve: Curves.easeOutCubic,
          scale: widget.getPosition() == 0 ? 1 : widget.getscaleFactor(),
          child: getChildBasedOnDismiss(widget.child),
        ),
      ),
    );
  }
}
