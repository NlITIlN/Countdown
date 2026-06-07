import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/notification_prefs.dart';
import '../theme_manager.dart';
import '../ui/layout.dart';

class ControlPanel extends StatefulWidget {
  const ControlPanel({
    super.key,
    required this.strings,
    required this.initialMinutes,
    required this.running,
    required this.notificationPrefs,
    required this.onTimerApply,
    required this.onLocaleChanged,
    required this.themeMode,
    required this.onThemeChanged,
    this.onReset,
  });

  final S strings;
  final int initialMinutes;
  final bool running;
  final NotificationPrefs notificationPrefs;
  final ValueChanged<int> onTimerApply;
  final ValueChanged<AppLocale> onLocaleChanged;
  final AppThemeMode themeMode;
  final ValueChanged<AppThemeMode> onThemeChanged;
  final VoidCallback? onReset;

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _minutes;
  late bool _soundEnabled;
  late bool _vibrationEnabled;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _minutes = widget.initialMinutes;
    _soundEnabled = widget.notificationPrefs.soundEnabled();
    _vibrationEnabled = widget.notificationPrefs.vibrationEnabled();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _setSoundEnabled(bool enabled) async {
    setState(() => _soundEnabled = enabled);
    await widget.notificationPrefs.saveSoundEnabled(enabled);
  }

  Future<void> _setVibrationEnabled(bool enabled) async {
    setState(() => _vibrationEnabled = enabled);
    await widget.notificationPrefs.saveVibrationEnabled(enabled);
  }

  @override
  Widget build(BuildContext context) {
    final metrics = AppMetrics.of(context);
    final scale = metrics.uiScale;
    final s = widget.strings;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        metrics.sp(24),
        metrics.sp(16),
        metrics.sp(24),
        metrics.sp(28) + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36 * scale,
            height: 4 * scale,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 46),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 20 * scale),
          // Tab bar
          TabBar(
            controller: _tabController,
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 140),
            tabs: [
              Tab(text: s.timer.toLowerCase()),
              Tab(text: s.settings.toLowerCase()),
            ],
          ),
          SizedBox(height: 20 * scale),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Timer tab
                _TimerTabContent(
                  strings: s,
                  initialMinutes: _minutes,
                  running: widget.running,
                  onMinutesChanged: (m) => setState(() => _minutes = m),
                  onApply: widget.onTimerApply,
                  onReset: widget.onReset,
                  scale: scale,
                ),
                // Settings tab
                _SettingsTabContent(
                  strings: s,
                  soundEnabled: _soundEnabled,
                  vibrationEnabled: _vibrationEnabled,
                  themeMode: widget.themeMode,
                  onThemeChanged: widget.onThemeChanged,
                  onSoundChanged: _setSoundEnabled,
                  onVibrationChanged: _setVibrationEnabled,
                  onLocaleChanged: widget.onLocaleChanged,
                  scale: scale,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerTabContent extends StatelessWidget {
  const _TimerTabContent({
    required this.strings,
    required this.initialMinutes,
    required this.running,
    required this.onMinutesChanged,
    required this.onApply,
    required this.onReset,
    required this.scale,
  });

  final S strings;
  final int initialMinutes;
  final bool running;
  final ValueChanged<int> onMinutesChanged;
  final ValueChanged<int> onApply;
  final VoidCallback? onReset;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Text(
            strings.setMinutes,
            style: TextStyle(
              fontSize: 13 * scale,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 148),
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: 16 * scale),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10 * scale,
            runSpacing: 10 * scale,
            children: [
              for (final preset in [1, 2, 3, 4, 5])
                _PresetButton(
                  minutes: preset,
                  selected: initialMinutes == preset,
                  onTap: () => onMinutesChanged(preset),
                  scale: scale,
                ),
            ],
          ),
          SizedBox(height: 16 * scale),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SheetIconButton(
                icon: Icons.remove,
                onTap: () => onMinutesChanged(
                  (initialMinutes - 1).clamp(1, 5),
                ),
              ),
              SizedBox(width: 28 * scale),
              Flexible(
                child: Text(
                  strings.minutesLabel(initialMinutes).toLowerCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40 * scale,
                    fontWeight: FontWeight.w300,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 230),
                  ),
                ),
              ),
              SizedBox(width: 28 * scale),
              _SheetIconButton(
                icon: Icons.add,
                onTap: () => onMinutesChanged(
                  (initialMinutes + 1).clamp(1, 5),
                ),
              ),
            ],
          ),
          SizedBox(height: 16 * scale),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8 * scale),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 16 * scale),
              activeTrackColor: Theme.of(context).colorScheme.primary,
              inactiveTrackColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 41),
              thumbColor: Theme.of(context).colorScheme.primary,
            ),
            child: Slider(
              value: initialMinutes.toDouble(),
              min: 1,
              max: 5,
              onChanged: (v) => onMinutesChanged(v.round()),
            ),
          ),
          SizedBox(height: 20 * scale),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 46),
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                disabledBackgroundColor: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 20),
                disabledForegroundColor: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 114),
                padding: EdgeInsets.symmetric(vertical: 14 * scale),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14 * scale),
                ),
              ),
              onPressed: running ? null : () => onApply(initialMinutes),
              child: Text(
                strings.apply,
                style: TextStyle(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.12,
                ),
              ),
            ),
          ),
          if (running && onReset != null) ...[
            SizedBox(height: 10 * scale),
            TextButton(
              onPressed: onReset,
              child: Text(strings.reset),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsTabContent extends StatelessWidget {
  const _SettingsTabContent({
    required this.strings,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onSoundChanged,
    required this.onVibrationChanged,
    required this.onLocaleChanged,
    required this.scale,
  });

  final S strings;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final AppThemeMode themeMode;
  final ValueChanged<AppThemeMode> onThemeChanged;
  final ValueChanged<bool> onSoundChanged;
  final ValueChanged<bool> onVibrationChanged;
  final ValueChanged<AppLocale> onLocaleChanged;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(text: strings.language, scale: scale),
          _LocaleTile(
            title: strings.russian,
            selected: strings.isRu,
            onTap: () => onLocaleChanged(AppLocale.ru),
          ),
          _LocaleTile(
            title: strings.english,
            selected: !strings.isRu,
            onTap: () => onLocaleChanged(AppLocale.en),
          ),
          SizedBox(height: 12 * scale),
          _SectionLabel(text: strings.theme, scale: scale),
          _ThemeTile(
            title: strings.themeDark,
            selected: themeMode == AppThemeMode.dark,
            onTap: () => onThemeChanged(AppThemeMode.dark),
          ),
          _ThemeTile(
            title: strings.themeLight,
            selected: themeMode == AppThemeMode.light,
            onTap: () => onThemeChanged(AppThemeMode.light),
          ),
          _ThemeTile(
            title: strings.themeNeon,
            selected: themeMode == AppThemeMode.neon,
            onTap: () => onThemeChanged(AppThemeMode.neon),
          ),
          SizedBox(height: 12 * scale),
          _SectionLabel(text: strings.notifications, scale: scale),
          _SettingsTile(
            title: strings.sound,
            value: soundEnabled,
            onChanged: onSoundChanged,
          ),
          _SettingsTile(
            title: strings.vibration,
            value: vibrationEnabled,
            onChanged: onVibrationChanged,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.text,
    required this.scale,
  });

  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8 * scale),
      child: Text(
        text.toLowerCase(),
        style: TextStyle(
          fontSize: 11 * scale,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 140),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _LocaleTile extends StatelessWidget {
  const _LocaleTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              Expanded(child: Text(title)),
              if (selected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                )
              else
                Icon(
                  Icons.radio_button_unchecked,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 102),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 102),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF6EE7A0),
          activeTrackColor: const Color(0xFF6EE7A0).withValues(alpha: 0.5),
        ),
      ],
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
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor:
            selected ? const Color(0xFF6EE7A0) : const Color(0xFF1A1A1A),
        foregroundColor:
            selected ? const Color(0xFF050505) : const Color(0xFF6EE7A0),
        padding: EdgeInsets.symmetric(
          horizontal: 16 * scale,
          vertical: 12 * scale,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14 * scale),
          side: selected
              ? BorderSide.none
              : const BorderSide(color: Color(0xFF6EE7A0), width: 1),
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
    return Material(
      color: const Color(0xFF222222),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: const Color(0xFFE8E8E8)),
        ),
      ),
    );
  }
}
