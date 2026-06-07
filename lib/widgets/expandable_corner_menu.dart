import 'package:flutter/material.dart';

class ExpandableCornerMenu extends StatefulWidget {
  const ExpandableCornerMenu({
    super.key,
    required this.size,
    required this.tooltip,
    required this.onAnalytics,
    required this.onSettings,
  });

  final double size;
  final String tooltip;
  final VoidCallback onAnalytics;
  final VoidCallback onSettings;

  @override
  State<ExpandableCornerMenu> createState() => _ExpandableCornerMenuState();
}

class _ExpandableCornerMenuState extends State<ExpandableCornerMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _select(VoidCallback action) {
    action();
    _toggle();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.size * 0.44;
    final spacing = widget.size * 0.16;

    return Tooltip(
      message: widget.tooltip,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            IgnorePointer(
              ignoring: !_open,
              child: Opacity(
                opacity: _animation.value,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.translate(
                      offset: Offset(-widget.size * 1.8 * (1 - _animation.value), 0),
                      child: _actionButton(
                        context,
                        icon: Icons.bar_chart,
                        label: 'analytics',
                        onTap: () => _select(widget.onAnalytics),
                      ),
                    ),
                    SizedBox(width: spacing),
                    Transform.translate(
                      offset: Offset(-widget.size * 0.9 * (1 - _animation.value), 0),
                      child: _actionButton(
                        context,
                        icon: Icons.settings_outlined,
                        label: 'settings',
                        onTap: () => _select(widget.onSettings),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IgnorePointer(
              ignoring: _open, // <-- блокируем клики по главной кнопке, если меню открыто
              child: FadeTransition(
                opacity: ReverseAnimation(_animation),
                child: _mainButton(context, iconSize),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mainButton(BuildContext context, double iconSize) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _toggle,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(
            child: _dotGraphic(context, iconSize),
          ),
        ),
      ),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Material(
        color: colorScheme.surfaceContainerHighest,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Icon(icon, size: widget.size * 0.45, color: colorScheme.primary),
          ),
        ),
      ),
    );
  }

  Widget _dotGraphic(BuildContext context, double size) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          3,
          (_) => Container(
            width: size * 0.2,
            height: size * 0.2,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
