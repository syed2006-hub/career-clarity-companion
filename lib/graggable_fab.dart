import 'package:careerclaritycompanion/features/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

class DraggableFab extends StatefulWidget {
  const DraggableFab({super.key});

  @override
  State<DraggableFab> createState() => _DraggableFabState();
}

class _DraggableFabState extends State<DraggableFab>
    with SingleTickerProviderStateMixin {
  late Offset _fabOffset;

  // Animation controller for snapping
  late final AnimationController _animationController;
  late Animation<Offset> _animation;

  bool _isInitialized = false;

  static const double _fabSize = 60.0;
  static const double _screenPadding = 20.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _animationController.addListener(() {
      setState(() {
        _fabOffset = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final screenSize = MediaQuery.of(context).size;
      final safeArea = MediaQuery.of(context).padding;

      // Initial position: bottom-right but a little higher
      _fabOffset = Offset(
        screenSize.width - _fabSize - _screenPadding, // Right side
        screenSize.height -
            safeArea.bottom -
            _fabSize -
            _screenPadding -
            80, // 80px higher from bottom
      );

      _isInitialized = true;
    }
  }

  Rect _getSafeBounds(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;

    return Rect.fromLTRB(
      safeArea.left + _screenPadding,
      safeArea.top + kToolbarHeight,
      screenSize.width - safeArea.right - _fabSize - _screenPadding,
      screenSize.height -
          safeArea.bottom -
          kBottomNavigationBarHeight -
          _fabSize -
          _screenPadding,
    );
  }

  Offset _clampOffset(Offset offset, Rect bounds) {
    return Offset(
      offset.dx.clamp(bounds.left, bounds.right),
      offset.dy.clamp(bounds.top, bounds.bottom),
    );
  }

  void _snapToEdge() {
    final screenSize = MediaQuery.of(context).size;
    final safeBounds = _getSafeBounds(context);

    final double targetX =
        (_fabOffset.dx + _fabSize / 2) < screenSize.width / 2
            ? safeBounds.left
            : safeBounds.right;

    final targetY = _fabOffset.dy;
    final targetOffset = _clampOffset(Offset(targetX, targetY), safeBounds);

    _animation = Tween<Offset>(begin: _fabOffset, end: targetOffset).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) return const SizedBox.shrink();

    return Positioned(
      left: _fabOffset.dx,
      top: _fabOffset.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            final newOffset = _fabOffset + details.delta;
            _fabOffset = _clampOffset(newOffset, _getSafeBounds(context));
          });
        },
        onPanEnd: (_) => _snapToEdge(),
        child: _buildOpenFab(context),
      ),
    );
  }

  Widget _buildOpenFab(BuildContext context) {
    return OpenContainer(
      transitionType: ContainerTransitionType.fade,
      closedElevation: 6,
      closedShape: const CircleBorder(),
      closedColor: Theme.of(context).primaryColor,
      closedBuilder:
          (context, openContainer) => SizedBox(
            width: _fabSize,
            height: _fabSize,
            child: FloatingActionButton(
              backgroundColor: Colors.black54,
              onPressed: openContainer,
              shape: const CircleBorder(),
              child: Image.network(
                'https://res.cloudinary.com/dui67nlwb/image/upload/v1756235987/unnamed-removebg-preview_1_thnonz.png',
              ),
            ),
          ),
      openBuilder: (context, closeContainer) => const ChatScreen(),
    );
  }
}
