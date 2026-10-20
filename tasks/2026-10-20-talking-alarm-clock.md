# Talking alarm clock rewrite

## Summary

Reimplemented the interval-clock prototype as a native iOS 26 alarm clock using AlarmKit, prepared English spoken-time audio, one-time and weekly schedules, snooze, local persistence, and recoverable changes. Added SwiftUI alarm/clock/about screens, a shared Xcode project, a portable Swift package, and macOS CI.

## Verification

- `swift test --scratch-path /tmp/clock-swift-build` in the official Swift 6.2 container (digest `sha256:d6f8f6112e9a63da0a4a151d6b93acd16699d35c0b82531ac1a245f5af210197`): 26 tests passed. The first run exposed Linux XCTest discovery incompatibility with synchronous main-actor tests; making those tests asynchronous fixed it.
- `swiftc -frontend -parse Sources/TalkingClock/*.swift` in that container: passed (syntax only, not Apple SDK type checking).
- `npx --yes prettier@3.8.3 --check '**/*.md' '.github/**/*.yml' .prettierrc`: passed.
- `git diff --check`, property-list parsing, and shared-scheme XML parsing: passed.
- Xcode is unavailable locally. macOS CI results will be recorded after the implementation PR runs.
- Physical-device delivery, sound behavior, accessibility, and App Store assets remain release gates.
