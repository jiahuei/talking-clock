# Talking Clock iOS App - Implementation Plan

## Overview
A clean, minimalistic iOS app that displays time and announces it at configurable intervals using system text-to-speech.

## Architecture
- **Framework**: SwiftUI (modern, declarative UI)
- **Pattern**: MVVM (appropriate for app scope)
- **Dependencies**: None - uses only system frameworks (AVFoundation for speech)
- **Target**: iOS 16+

## Project Structure
```
TalkingClock/
├── App/
│   └── TalkingClockApp.swift          # Entry point
├── Models/
│   ├── TimeUnit.swift                  # seconds/minutes enum with intervals
│   └── ClockSettings.swift             # Settings with UserDefaults persistence
├── ViewModels/
│   ├── ClockViewModel.swift            # Timer, announcements, state
│   └── SpeechService.swift             # AVSpeechSynthesizer wrapper
├── Services/
│   └── NotificationService.swift       # Local notification scheduling
├── Views/
│   ├── ContentView.swift               # Main layout
│   ├── DigitalClockView.swift          # Prominent time display
│   ├── AnalogClockView.swift           # Canvas-drawn clock (optional)
│   ├── IntervalPickerView.swift        # Two dropdowns
│   └── SettingsToggleView.swift        # Analog clock toggle
└── Resources/
    └── Assets.xcassets/                # Colors, app icon
```

## Key Components

### 1. TimeUnit Enum
- Cases: `.seconds`, `.minutes`
- Property: `availableIntervals` → seconds: [10, 20, 30], minutes: [1, 2, 5, 10, 15, 30]
- Method: `intervalInSeconds(_ value: Int)` → converts to TimeInterval

### 2. ClockSettings Model
- Properties: `intervalValue`, `timeUnit`, `showAnalogClock`, `isAnnouncementEnabled`
- Persistence via UserDefaults with Codable

### 3. SpeechService
- Wraps `AVSpeechSynthesizer`
- Configures audio session for playback
- Method: `speak(_ text: String)`

### 4. NotificationService
- Schedules local notifications for background announcements
- Manages notification permissions
- Reschedules when interval settings change

### 5. ClockViewModel
- `@Published currentTime` - updates every second
- `@Published settings` - persisted configuration
- Checks announcement timing against interval (aligned to clock, e.g., at :00, :05, :10)
- Manual `speakCurrentTime()` trigger

### 6. Views
- **DigitalClockView**: Large `HH:mm:ss` with date subtitle, thin rounded font, system-default format
- **AnalogClockView**: SwiftUI Canvas with hour markers, hour/minute/second hands
- **IntervalPickerView**: Two `Picker` controls with `.menu` style
- **SettingsToggleView**: Toggle for analog clock visibility and auto-announce

## UI Layout (ContentView)
```
┌─────────────────────────┐
│                         │
│     [Analog Clock]      │  ← optional, toggleable
│                         │
│       14:35:22          │  ← prominent digital clock
│    Monday, January 20   │
│                         │
│    Speak time every     │
│    [ 5 ▼] [minutes ▼]   │  ← two dropdowns
│                         │
│  ☐ Show Analog Clock    │  ← toggles
│  ☑ Auto-Announce Time   │
│                         │
│    [🔊 Speak Time]      │  ← manual button
│                         │
└─────────────────────────┘
```

## Background Announcements Strategy
Two approaches combined for reliability:

### Primary: Local Notifications with Speech
- Schedule `UNNotificationRequest` for each upcoming announcement
- Use notification content with spoken announcement via `UNNotificationSound`
- Reschedule notifications when interval changes
- Works even when app is terminated

### Secondary: Background Audio Session
- Add `UIBackgroundModes: audio` to Info.plist
- Audio session category: `.playback` with `.duckOthers`
- Continue announcements while audio session is active

Note: PiP mode is not suitable (designed for video, likely App Store rejection)

## Implementation Order

1. **Create Xcode project** - iOS App, SwiftUI, Swift
2. **Models** - TimeUnit enum, ClockSettings with persistence
3. **SpeechService** - AVSpeechSynthesizer with audio session config
4. **NotificationService** - Local notification scheduling for background
5. **ClockViewModel** - Timer, announcement logic, state management
6. **DigitalClockView** - Typography, layout
7. **IntervalPickerView** - Two connected pickers
8. **SettingsToggleView** - Analog and auto-announce toggles
9. **AnalogClockView** - Canvas drawing with clock hands
10. **ContentView** - Compose all views, animations
11. **Notification permission** - Request on first launch
12. **Polish** - App icon, launch screen, testing

## Verification
1. Build and run in Simulator/device
2. Verify digital clock updates every second
3. Test interval picker changes (values should persist after restart)
4. Toggle analog clock visibility
5. Wait for scheduled announcement to trigger
6. Tap "Speak Time" button for manual announcement
7. Test persistence by killing and reopening app
8. Test dark mode appearance
9. Test background notifications trigger when app is backgrounded
