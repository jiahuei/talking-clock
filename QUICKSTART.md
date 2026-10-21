# Development

For first-time Mac setup and the complete release process, see the [App Store publishing guide](docs/app-store-publishing.md).

## Run on iPhone or simulator

1. Install Xcode 26+ on a compatible Mac.
2. Open `TalkingClock.xcodeproj` and select the shared `TalkingClock` scheme.
3. Select an iOS 26+ simulator, or connect an iPhone and select your development team under Signing & Capabilities. Change the bundle identifier if necessary.
4. Run, add an alarm, and allow alarm access when asked. Permissions are requested when enabling an alarm, not at launch.
5. Preview the spoken sound in the editor. To test system delivery, set an alarm a few minutes ahead, save, then lock the device.

The app uses an English voice. With speech off, it uses the system alarm sound. To snooze, tap Open on the system alert and use the app's Snooze button; system Stop dismisses the alarm. There is no countdown Live Activity.

## Automated checks

From the repository root:

```sh
swift format lint --strict --recursive Package.swift Sources Tests
swift test
xcodebuild -project TalkingClock.xcodeproj -scheme TalkingClock -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
npx --yes prettier@3.8.3 --check '**/*.md' '.github/**/*.yml' .prettierrc
git diff --check
```

Formatting CI runs on every branch push. Swift checks use the official `swift format` tool bundled with Swift 6+, pinned to Swift 6.2.4 in CI. The `.swift-format` configuration keeps four-space indentation and a 120-column line length. To apply formatting, run `swift format format --in-place --recursive Package.swift Sources Tests` with the same toolchain. The archived `v0/` is excluded.

On pull requests, pushes to `main`, and tags matching `v*`, iOS CI runs package tests, an unsigned simulator build, and a launch smoke test on macOS with Xcode 26. It uploads a launch screenshot. These checks do not prove physical-device alarm delivery.

## Storage and recovery

The app stores versioned JSON in Application Support/TalkingClock and generated PCM voice clips in Library/Sounds. Clips are shared by spoken time and contain no personal alarm labels. The archive's `clockSettings` key is not migrated because it contains interval-clock preferences, not alarms.

A change journal is saved before touching system alarms. Replacement alarms are scheduled before old registrations are cancelled. If a change fails, use **Retry sync** to finish it or **Discard change** to restore the previous configuration. A pending change blocks further edits; old schedules can remain active until retry succeeds. Relaunching does not automatically replay a pending change or re-arm a missing alarm. An unreadable file is preserved and writes are blocked.

One-time alarms and snoozes use fixed dates. Weekly alarms follow local wall-clock time through AlarmKit. The next-alarm display uses Calendar's next-valid-time/first-repeated-time policy; verify OS delivery behavior around DST on real devices.

## Device acceptance

Run the checklist in [the implementation plan](docs/implementation-plan.md) and [release checklist](APP_STORE_CHECKLIST.md). Test foreground, locked, terminated, restart/unlock, silent mode, Focus, authorization denial/revocation, repeat alarms, simultaneous alarms, and snooze. Check that the custom recording is audible and that old registrations stop firing after edits.

## Archived prototype

`v0/TalkingClock/TalkingClock.xcodeproj` is the original interval clock. It is preserved for reference and is excluded from the new app, tests, and formatting checks.
