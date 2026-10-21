# Talking Clock implementation plan

## Motivation and v0 review

The original implementation is preserved byte-for-byte in `v0/`. It displays time, offers manual speech, persists settings, and checks announcement intervals with an in-process timer. `PLAN-alarm.md` describes alarms but does not implement them.

The rewrite addresses these findings:

| Finding | Consequence | Decision |
| --- | --- | --- |
| `NotificationService` assigns `.default` to notification sound | Notification text is not spoken audio | Generate a speech sound before scheduling |
| Timer drives announcements; audio background mode is declared | Suspension is not a dependable alarm trigger | System-managed AlarmKit schedules |
| Notifications are a rolling batch of 60 | Delivery ends unless the app replenishes the batch | Native weekly recurrence |
| Every settings change removes all pending notifications | A new alarm implementation would risk unrelated cancellations | Cancel only owned alarm IDs |
| Settings decoding silently falls back | Corruption can hide user state | Explicit storage errors |
| No alarm model, CRUD, firing UI, tests, or shared scheme | The alarm proposal is not a runnable feature | New app, portable domain, tests, and CI |
| Proposed maximum-volume manipulation, purchases, and background modes | Unnecessary complexity and platform risks | Follow system volume and omit monetization |

## Architecture

`AlarmCore` owns validated records, weekday selection, next-occurrence calculations, storage, and a store tested through a scheduler protocol. The SwiftUI app owns presentation and AlarmKit/AVFoundation adapters. Persist desired state before system mutation and reconcile observed system state; surface failures instead of pretending that disk and system scheduling are one transaction.

AlarmKit on iOS 26 is the minimum target because this product needs real alarms while suspended or terminated. Use a custom PCM chime and speech clip in `Library/Sounds`; no runtime speech callback is required at alarm delivery. A preview uses the same generated clip. Keep an on-demand live-time speech control on the clock screen.

Snooze is a separate fixed-date alarm initiated in the app. The system alert offers an Open action to reach controls. Do not add countdown presentations without the required Live Activity widget extension.

## Visual direction

Use a spacious clock face and large rounded numerals, a warm amber accent, a next-alarm summary, rounded alarm cards, and native sheets/toggles. Prefer semantic surfaces that adapt to light and dark appearances. Make the primary action obvious and provide a useful empty state without activating sample alarms.

## Milestones

1. Foundation PR: preserve `v0`, establish agent instructions, ignore rules, formatting CI, specifications, and this review.
2. App PR: implement the core and tests, sound generation, AlarmKit integration, alarm/clock/settings screens, editor, preview, stop/snooze, persistence, and reconciliation.
3. Verification: run portable tests, unsigned simulator build, formatting, and diff checks; inspect CI results.
4. Release gate: physical-device testing and App Store assets/signing. Do not mark this complete from a Linux build environment.

## Acceptance tests

- Add a one-time alarm two minutes ahead, close the app, lock the device, and hear the chosen time when it rings.
- Repeat with silent mode and Focus enabled; verify the system alarm presentation and custom sound.
- Stop a one-time alarm in system UI, reopen, and verify it is no longer enabled.
- Edit, disable, and delete an alarm; verify obsolete registrations no longer fire.
- Snooze in the app; verify a new spoken time and that a repeating parent remains scheduled.
- Deny/revoke authorization; verify actionable errors and no misleading enabled state.
- Restart the app and device; verify persistence and system registration reconciliation.
- Test midnight, week rollover, DST gaps/overlaps, time-zone changes, concurrent save attempts, corrupt storage, and scheduler failures.
- Test VoiceOver, accessibility text sizes, light/dark mode, and compact/regular layouts.

## Primary references

- [AlarmKit overview](https://developer.apple.com/documentation/alarmkit)
- [Apple's scheduling sample](https://developer.apple.com/documentation/alarmkit/scheduling-an-alarm-with-alarmkit)
- [Custom alert sounds](<https://developer.apple.com/documentation/activitykit/alertconfiguration/alertsound/named(_:)>)
- [Writing synthesized speech to audio buffers](<https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer/write(_:tobuffercallback:)>)
