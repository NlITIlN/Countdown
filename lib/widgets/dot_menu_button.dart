import 'package:flutter/material.dart';

enum DotMenuType { analytics, settings }

class DotMenuButton extends StatelessWidget {
  const DotMenuButton({
    super.key,
    required this.size,
    required this.tooltip,
    required this.onTap,
    required this.type,
  });

  final double size;
  final String tooltip;
  final VoidCallback onTap;
  final DotMenuType type;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colorScheme.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: _DotMenuGraphic(type: type, size: size * 0.56),
            ),
          ),
        ),
      ),
    );
  }
}

class _DotMenuGraphic extends StatelessWidget {
  const _DotMenuGraphic({required this.type, required this.size});
  final DotMenuType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    // outer 3-dot indicator
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // three small dots arranged vertically
          Positioned(
            left: size * 0.06,
            child: _dot(context),
          ),
          Positioned(
            child: _dot(context),
          ),
          Positioned(
            right: size * 0.06,
            child: _dot(context),
          ),
          // inner graphic depending on type
          if (type == DotMenuType.analytics) _analyticsBars(context),
          if (type == DotMenuType.settings) _settingsBars(context),
        ],
      ),
    );
  }

  Widget _dot(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size * 0.16,
      height: size * 0.16,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _analyticsBars(BuildContext context) {
    // three vertical bars of different heights
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _bar(context, heightFactor: 0.45),
        SizedBox(width: size * 0.06),
        _bar(context, heightFactor: 0.7),
        SizedBox(width: size * 0.06),
        _bar(context, heightFactor: 0.9),
      ],
    );
  }

  Widget _settingsBars(BuildContext context) {
    // three horizontal side-bars to represent params
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hbar(context, widthFactor: 0.7),
        SizedBox(height: size * 0.08),
        _hbar(context, widthFactor: 0.5),
        SizedBox(height: size * 0.08),
        _hbar(context, widthFactor: 0.9),
      ],
    );
  }

  Widget _bar(BuildContext context, {required double heightFactor}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size * 0.12,
      height: size * heightFactor,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(size * 0.02),
      ),
    );
  }

  Widget _hbar(BuildContext context, {required double widthFactor}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size * widthFactor,
      height: size * 0.12,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(size * 0.02),
      ),
    );
  }
}
