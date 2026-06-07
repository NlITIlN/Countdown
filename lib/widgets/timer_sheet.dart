import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../ui/layout.dart' show AppMetrics;

class TimerSheetContent extends StatefulWidget {
  const TimerSheetContent({
    super.key,
    required this.strings,
    required this.initialMinutes,
    required this.running,
    required this.onApply,
    this.onReset,
  });

  final S strings;
  final int initialMinutes;
  final bool running;
  final ValueChanged<int> onApply;
  final VoidCallback? onReset;

  @override
  State<TimerSheetContent> createState() => _TimerSheetContentState();
}

class _TimerSheetContentState extends State<TimerSheetContent> {
  late int minutes;

  @override
  void initState() {
    super.initState();
    minutes = widget.initialMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final sheetMetrics = AppMetrics.of(context);
    final scale = sheetMetrics.uiScale;
    final s = widget.strings;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        sheetMetrics.sp(24),
        sheetMetrics.sp(16),
        sheetMetrics.sp(24),
        sheetMetrics.sp(28) + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36 * scale,
            height: 4 * scale,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 20 * scale),
          Text(
            s.setMinutes,
            style: TextStyle(
              fontSize: 17 * scale,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 24 * scale),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10 * scale,
            runSpacing: 10 * scale,
            children: [
              for (final preset in [5, 10, 15, 30])
                _PresetButton(
                  minutes: preset,
                  selected: minutes == preset,
                  onTap: () => setState(() {
                    minutes = preset;
                  }),
                  scale: scale,
                ),
            ],
          ),
          SizedBox(height: 20 * scale),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SheetIconButton(
                icon: Icons.remove,
                onTap: () => setState(() {
                  minutes = (minutes - 1).clamp(1, 30);
                }),
              ),
              SizedBox(width: 28 * scale),
              Text(
                s.minutesLabel(minutes),
                style: TextStyle(
                  fontSize: 40 * scale,
                  fontWeight: FontWeight.w300,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(width: 28 * scale),
              _SheetIconButton(
                icon: Icons.add,
                onTap: () => setState(() {
                  minutes = (minutes + 1).clamp(1, 30);
                }),
              ),
            ],
          ),
          SizedBox(height: 20 * scale),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8 * scale),
              overlayShape:
                  RoundSliderOverlayShape(overlayRadius: 16 * scale),
              activeTrackColor: colorScheme.onSurface.withValues(alpha: 0.6),
              inactiveTrackColor: colorScheme.onSurface.withValues(alpha: 0.12),
              thumbColor: colorScheme.onSurface,
            ),
            child: Slider(
              value: minutes.toDouble(),
              min: 1,
              max: 30,
              onChanged: (v) => setState(() => minutes = v.round()),
            ),
          ),
          SizedBox(height: 8 * scale),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(vertical: 14 * scale),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14 * scale),
                ),
              ),
              onPressed: () => widget.onApply(minutes),
              child: Text(
                s.apply,
                style: TextStyle(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (widget.running && widget.onReset != null) ...[
            SizedBox(height: 10 * scale),
            TextButton(
              onPressed: widget.onReset,
              child: Text(s.reset),
            ),
          ],
        ],
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.minutes,
    required this.selected,
    required this.onTap,
    required this.scale,
  });

  final int minutes;
  final bool selected;
  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: selected
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest,
        foregroundColor: selected
            ? colorScheme.onPrimary
            : colorScheme.primary,
        padding: EdgeInsets.symmetric(
          horizontal: 16 * scale,
          vertical: 12 * scale,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14 * scale),
          side: selected
              ? BorderSide.none
              : BorderSide(color: colorScheme.primary, width: 1),
        ),
      ),
      onPressed: onTap,
      child: Text(
        '$minutes',
        style: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SheetIconButton extends StatelessWidget {
  const _SheetIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: colorScheme.onSurface),
        ),
      ),
    );
  }
}
