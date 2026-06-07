import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/notification_prefs.dart';
import '../ui/layout.dart';

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({
    super.key,
    required this.strings,
    required this.notificationPrefs,
    required this.onLocaleChanged,
  });

  final S strings;
  final NotificationPrefs notificationPrefs;
  final ValueChanged<AppLocale> onLocaleChanged;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late bool _soundEnabled;
  late bool _vibrationEnabled;

  @override
  void initState() {
    super.initState();
    _soundEnabled = widget.notificationPrefs.soundEnabled();
    _vibrationEnabled = widget.notificationPrefs.vibrationEnabled();
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

    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        metrics.sp(24),
        metrics.sp(16),
        metrics.sp(24),
        metrics.sp(20) + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36 * scale,
              height: 4 * scale,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 20 * scale),
          Text(
            widget.strings.settings.toLowerCase(),
            style: TextStyle(
              fontSize: 17 * scale,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
              letterSpacing: 0.5,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20 * scale),
                  _SectionLabel(text: widget.strings.language, scale: scale),
                  _LocaleTile(
                    title: widget.strings.russian,
                    selected: widget.strings.isRu,
                    onTap: () => widget.onLocaleChanged(AppLocale.ru),
                  ),
                  _LocaleTile(
                    title: widget.strings.english,
                    selected: !widget.strings.isRu,
                    onTap: () => widget.onLocaleChanged(AppLocale.en),
                  ),
                  SizedBox(height: 12 * scale),
                  _SectionLabel(text: widget.strings.theme, scale: scale),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      widget.strings.themeSoon,
                      style: TextStyle(
                        fontSize: 16 * scale,
                        color: colorScheme.onSurface.withValues(alpha: 0.38),
                      ),
                    ),
                    trailing: Icon(
                      Icons.lock_outline,
                      size: 18 * scale,
                      color: colorScheme.onSurface.withValues(alpha: 0.24),
                    ),
                  ),
                  SizedBox(height: 16 * scale),
                  _SectionLabel(text: widget.strings.notifications, scale: scale),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      widget.strings.sound,
                      style: TextStyle(
                        fontSize: 16 * scale,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    value: _soundEnabled,
                    onChanged: _setSoundEnabled,
                    activeThumbColor: colorScheme.primary,
                    subtitle: Text(
                      widget.strings.soundDescription,
                      style: TextStyle(
                        fontSize: 13 * scale,
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      widget.strings.vibration,
                      style: TextStyle(
                        fontSize: 16 * scale,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    value: _vibrationEnabled,
                    onChanged: _setVibrationEnabled,
                    activeThumbColor: colorScheme.primary,
                    subtitle: Text(
                      widget.strings.vibrationDescription,
                      style: TextStyle(
                        fontSize: 13 * scale,
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  SizedBox(height: 16 * scale),
                  Divider(color: colorScheme.onSurface.withValues(alpha: 0.12), height: 1),
                  SizedBox(height: 16 * scale),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.scale});

  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      text.toLowerCase(),
      style: TextStyle(
        fontSize: 13 * scale,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface.withValues(alpha: 0.3),
        letterSpacing: 0.3,
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
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: TextStyle(color: colorScheme.onSurface)),
      trailing: selected
          ? Icon(Icons.check, color: colorScheme.primary, size: 20)
          : null,
      onTap: onTap,
    );
  }
}
