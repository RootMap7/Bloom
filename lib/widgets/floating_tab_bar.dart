import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FloatingTabBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabChanged;
  final VoidCallback? onAddPressed;

  const FloatingTabBar({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
    this.onAddPressed,
  });

  @override
  State<FloatingTabBar> createState() => _FloatingTabBarState();
}

class _FloatingTabBarState extends State<FloatingTabBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _dragOffset = 0;
  bool _isDragging = false;
  int _targetIndex = 0;

  // Tab configuration
  final List<TabItem> _tabs = [
    TabItem(
      activeIcon: 'assets/images/home-active.svg',
      inactiveIcon: 'assets/images/home-inactive.svg',
      label: 'Home',
    ),
    TabItem(
      activeIcon: 'assets/images/ourlist-active.svg',
      inactiveIcon: 'assets/images/ourlist-inactive.svg',
      label: 'Our List',
    ),
    TabItem(
      activeIcon: 'assets/images/profile_active.svg',
      inactiveIcon: 'assets/images/profile-inactive.svg',
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _targetIndex = widget.currentIndex;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FloatingTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex && !_isDragging) {
      _animateToIndex(widget.currentIndex);
    }
  }

  void _animateToIndex(int index) {
    setState(() {
      _targetIndex = index;
    });
    _animationController.forward(from: 0);
  }

  void _handleTap(int index) {
    if (_isDragging) return;
    _animateToIndex(index);
    widget.onTabChanged(index);
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragOffset = 0;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details, double itemWidth) {
    setState(() {
      _dragOffset += details.delta.dx;
      // Clamp the drag offset to prevent dragging too far
      final maxOffset = itemWidth * (_tabs.length - 1);
      _dragOffset = _dragOffset.clamp(-itemWidth * _targetIndex,
          maxOffset - (itemWidth * _targetIndex));
    });
  }

  void _handleDragEnd(DragEndDetails details, double itemWidth) {
    // Calculate which tab we should snap to
    final currentPosition = (_targetIndex * itemWidth) + _dragOffset;
    final newIndex = (currentPosition / itemWidth).round().clamp(0, _tabs.length - 1);

    setState(() {
      _isDragging = false;
      _dragOffset = 0;
      _targetIndex = newIndex;
    });

    _animationController.forward(from: 0);
    widget.onTabChanged(newIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 34,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Main pill-shaped tab bar
          Expanded(
            child: _buildMainTabBar(),
          ),
          const SizedBox(width: 12),
          // Circular add button
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildMainTabBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / _tabs.length;

        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    blurRadius: 0,
                    offset: const Offset(0, -1),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Liquid glass selection indicator
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      final currentIndex = _isDragging ? _targetIndex : widget.currentIndex;
                      final targetPosition = _targetIndex * itemWidth;
                      final currentPosition = currentIndex * itemWidth;
                      final animatedPosition = _isDragging
                          ? targetPosition + _dragOffset
                          : currentPosition +
                              ((targetPosition - currentPosition) * _animation.value);

                      return Positioned(
                        left: animatedPosition,
                        top: 6,
                        child: GestureDetector(
                          onHorizontalDragStart: _handleDragStart,
                          onHorizontalDragUpdate: (details) =>
                              _handleDragUpdate(details, itemWidth),
                          onHorizontalDragEnd: (details) =>
                              _handleDragEnd(details, itemWidth),
                          child: Container(
                            width: itemWidth,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF7C3ABA).withOpacity(0.85),
                                  const Color(0xFF9B6DD6).withOpacity(0.85),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7C3ABA).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Tab items
                  Row(
                    children: List.generate(_tabs.length, (index) {
                      return Expanded(
                        child: _buildTabItem(index),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabItem(int index) {
    final isActive = widget.currentIndex == index || _targetIndex == index;
    final tab = _tabs[index];

    return GestureDetector(
      onTap: () => _handleTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: SvgPicture.asset(
              isActive ? tab.activeIcon : tab.inactiveIcon,
              key: ValueKey('$index-$isActive'),
              width: 28,
              height: 28,
              colorFilter: ColorFilter.mode(
                isActive ? Colors.white : const Color(0xFF4D4B4B).withOpacity(0.6),
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: widget.onAddPressed,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF7C3ABA),
                  Color(0xFF9B6DD6),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3ABA).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}

class TabItem {
  final String activeIcon;
  final String inactiveIcon;
  final String label;

  TabItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
  });
}
