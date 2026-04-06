# Streakit

A habit tracker app focused on building and maintaining streaks. Track daily habits, stay consistent, and celebrate milestones — with dark mode and local reminders.

## Features

- **Streak tracking** — visualize current and best streaks per habit
- **Today view** — check off habits for the day at a glance
- **Stats** — progress overview across all habits
- **Reminders** — local notifications to keep you on track
- **Onboarding** — starter habit templates to hit the ground running
- **Dark mode** — system-aware theme with manual toggle
- **Data export** — export your habit data as JSON

## Tech Stack

- **Flutter** — UI framework (Android-first)
- **Riverpod** — state management (with code generation)
- **Drift** — local SQLite database
- **GoRouter** — navigation
- **flutter_local_notifications** — reminder notifications

## Getting Started

**Requirements:** Flutter SDK ^3.11.4, Android device or emulator

```bash
git clone https://github.com/ZeeetOne/streakit.git
cd streakit
flutter pub get
flutter run
```

To regenerate database/provider code after schema changes:

```bash
dart run build_runner build --delete-conflicting-outputs
```
