# Talking alarm clock rewrite

## Summary

Reimplemented the interval-clock prototype as a native iOS 26 alarm clock using AlarmKit, prepared English spoken-time audio, one-time and weekly schedules, snooze, local persistence, and recoverable changes. Added SwiftUI alarm/clock/about screens, a shared Xcode project, a portable Swift package, and macOS CI.

## Verification

- Local Xcode/Swift checks unavailable: this workspace is Linux without either toolchain. macOS CI results will be recorded after the implementation PR runs.
- Physical-device delivery, sound behavior, accessibility, and App Store assets remain release gates.
