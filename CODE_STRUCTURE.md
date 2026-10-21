# Project code structure — Countdown

Folder layout and responsibilities of the main Dart files.

## Top-level folders

- `lib/` — application source code (UI, screens, services, models, theming, localization).
- `test/` — unit and widget tests.
- `android/`, `ios/`, `windows/` — platform projects and native integration.
- `.github/workflows/` — CI: `flutter analyze` and `flutter test` on every push / pull request.

---

## `lib/`

- `main.dart` — entry point. Loads `SharedPreferences`, initializes notifications, restores locale and theme, builds `CountdownApp`.
- `theme_manager.dart` — `AppThemeMode` (dark / light / neon) → `ThemeData`.

### Localization (`l10n/`)
- `strings.dart` — `S`: all RU / EN user-facing strings, including notification and achievement texts. `S.forRu(isRu)` for services that only know the language flag.
- `strings_plurals.dart` — strings that need Russian plural forms (`sessionsLabel`, `timesOnDay`, `achievementRecordBody`, `dayActivity`).
- `strings_formatters.dart` — date formatting and badge titles.

### Models (`models/`)
- `day_usage.dart` — usage for one day: `{ date, count }`.
- `usage_stats.dart` — statistics built from stored timestamps: total count, per-day list, streak, badge key, `getTodayCount()` / `getYesterdayCount()` / `getMaxDayCount()`.

### Screens (`screens/`)
- `home_screen.dart` — main screen: the timer ring in the center and the corner menu (statistics, settings). Wires taps to `HomeTimerController`.
- `home_timer_controller.dart` — timer logic and state (`TimerState`: idle, running, critical, completed):
  - `bootstrap()` restores a running timer from the saved `endsAt`, or records a timer that finished while the app was closed;
  - `start()` / `reset()` (tap on the ring = start or reset; no pause by design);
  - `syncFromClock()` — 1 s ticker and on app resume;
  - `handleCompletion()` — guarded against double completion, records usage, shows the done notification, then badges / achievements;
  - achievements: daily record, streak ≥ 3 days, comeback after 3+ days; each type at most once per day, one reward per completion, a badge takes priority.
- `analytics_screen.dart` — statistics: summary, 30-day activity timeline with fading, per-day breakdown.

### Services (`services/`)
- `notification_service.dart` — cross-platform facade: `init()`, `requestPermission()`, `scheduleSteps()` (schedules the completion notification), `cancelSteps()`, `showDone()`, `showBadge()`, `showAchievement()`.
- `_mobile_notification_handler.dart` — Android / iOS via `flutter_local_notifications` + timezone. One Android channel per sound / vibration combination (on Android 8+ these are channel settings). Exact alarms when allowed, inexact otherwise.
- `_desktop_notification_handler.dart` — Windows / macOS / Linux toasts via `local_notifier`, scheduling via in-process timers.
- `notification_prefs.dart` — sound / vibration settings; per-type "achievement shown today" flags.
- `timer_prefs.dart` — timer limits (`minMinutes`, `maxMinutes`, `defaultMinutes`, `clampMinutes`), saved minutes and `endsAt`.
- `usage_store.dart` — completion timestamps (last 500) plus an all-time counter; tolerant to corrupted data.
- `theme_prefs.dart` — saved theme.

### UI primitives (`ui/`)
- `layout.dart` — `AppMetrics` (sizes derived from the screen; reference: iPhone 12 mini) and `ResponsiveShell` (centered column on wide screens).
- `rings_timer_button.dart` — the three-ring timer button: progress arc, critical pulse, completion fade / resurface, press flash. Exposes `Semantics` for screen readers.

### Widgets (`widgets/`)
- `control_panel.dart` — settings page with two tabs: timer (presets, ±, slider) and settings (language, theme, sound, vibration).
- `expandable_corner_menu.dart` — the "⋯" corner menu that expands into statistics and settings buttons.

---

## `test/`

- `widget_test.dart` — smoke test: `HomeScreen` boots and shows the timer.
- `home_timer_controller_achievement_test.dart` — achievement rules and dedupe, badge priority, double-completion guard, completed → idle transition.
- `usage_store_test.dart` — all-time counter beyond the 500-event limit, corrupted data, timer restore state.
- `usage_stats_test.dart` — grouping by day, streak.
- `prefs_test.dart` — timer and notification preferences.

---

## Notification flow

1. `HomeTimerController.start()` / `bootstrap()` → `NotificationService.scheduleSteps()` schedules the completion notification at `endsAt`.
2. On completion → `cancelSteps()`, `showDone()`, then `_notifyMilestones()` (badge) or `_checkAchievements()`.
