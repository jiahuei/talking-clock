# Talking Clock

A native SwiftUI alarm clock for iPhone and iPad on **iOS 26+**. A chime and an English voice announce the scheduled alarm time using AlarmKit's system-managed custom sound, including while the app is closed.

- One-time alarms and custom weekly repeats.
- Editable labels, enable/disable, voice preview, and per-alarm snooze length.
- System Stop and Open controls; in-app snooze preserves repeating alarms.
- Next-alarm summary, live analog clock, and on-demand time speech.
- Local persistence with recoverable scheduling changes; no account, tracking, or runtime dependencies.

Open `ios/TalkingClock.xcodeproj` in **Xcode 26+**, select the shared `TalkingClock` scheme, and run. See [QUICKSTART.md](QUICKSTART.md) for signing, tests, and device checks.

To ship the app, follow the [App Store publishing guide](docs/app-store-publishing.md), from installing Xcode on your MacBook through signing, TestFlight, review, and public release.

The voice is a recording of the configured alarm time, not a live announcement that changes while ringing. Delayed delivery or a DST adjustment can differ from the recorded time. Custom sound behavior must be validated on physical iOS hardware before release; see [APP_STORE_CHECKLIST.md](APP_STORE_CHECKLIST.md).

## Repository

- `ios/`: current app, Xcode project, Swift package, configuration, and tests.
- `ios/Sources/TalkingClock/`: SwiftUI screens, AlarmKit adapter, and AVFoundation audio.
- `ios/Sources/AlarmCore/`: records, calendar calculations, persistence, and recoverable store.
- `ios/Tests/AlarmCoreTests/`: domain and failure-path tests; run `swift test --package-path ios` from the repository root.
- `v0/`: original prototype, preserved unchanged.
- [Specification](docs/SPEC.md), [conventions](docs/CONVENTIONS.md), and [implementation plan / v0 review](docs/implementation-plan.md).
