# Talking Clock

A native SwiftUI talking clock for iPhone and iPad on **iOS 26+**, with **Clock**, **Alarm**, and **Timer** tools and the Halo Ramp sky-and-ring design.

- Clock: tap to hear natural English time, or choose foreground announcements on 5/15/30/60-minute boundaries.
- Alarm: one-time or weekly repeats, spoken time and label, previews, confirmed deletion, and 2–15 minute snoozes shown under their parent.
- Timer: presets or a custom 1-second to 23:59:59 duration, pause/resume/reset, foreground remaining-time speech, and an AlarmKit final alert with a countdown Live Activity.
- Local persistence and recoverable alarm scheduling; no account, analytics, purchases, or runtime network dependency.

**Work in progress:** locked-screen interval speech and selectable ringing cadence are gated on physical-device experiments. The native Mac requirements from #4 are tracked under #7. See [delivery status and remaining gates](docs/delivery-investigation.md); this branch does not establish release readiness.

Open `ios/TalkingClock.xcodeproj` in **Xcode 26+**, select the shared `TalkingClock` scheme, and run. See [QUICKSTART.md](QUICKSTART.md) for signing, tests, and device checks.

To ship the app, follow the [App Store publishing guide](docs/app-store-publishing.md), from installing Xcode on your MacBook through signing, TestFlight, review, and public release.

The alarm voice is a recording of its configured time and label; it does not change while ringing. Delayed delivery or a DST adjustment can differ from the recorded time. Custom sound behavior must be validated on physical iOS hardware before release; see [APP_STORE_CHECKLIST.md](APP_STORE_CHECKLIST.md).

## Repository

- `ios/`: current app, Xcode project, Swift package, configuration, and tests.
- `ios/Sources/TalkingClock/`: SwiftUI screens, AlarmKit adapter, and AVFoundation audio.
- `ios/Sources/AlarmCore/`: records, calendar calculations, persistence, and recoverable store.
- `ios/Tests/AlarmCoreTests/`: domain and failure-path tests; run `swift test --package-path ios` from the repository root.
- `v0/`: original prototype, preserved unchanged.
- [Specification](docs/SPEC.md), [conventions](docs/CONVENTIONS.md), and [implementation plan / v0 review](docs/implementation-plan.md).
