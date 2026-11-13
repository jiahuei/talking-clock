# Talking Clock implementation plan

## Motivation and v0 review

The original implementation is preserved byte-for-byte in `v0/`. It displays time, offers manual speech, persists settings, and checks announcement intervals with an in-process timer. `PLAN-alarm.md` describes alarms but does not implement them.

The rewrite addresses these findings:

| Finding | Consequence | Decision |
| --- | --- | --- |
| `NotificationService` assigns `.default` to notification sound | Notification text is not spoken audio | Generate a speech sound before scheduling |
| Timer drives announcements; audio background mode is declared | Suspension is not a dependable alarm trigger | AlarmKit for alarms and timer completion; prototype a user-started continuous speech programme before production background intervals |
| Notifications are a rolling batch of 60 | Delivery ends unless the app replenishes the batch | Native weekly recurrence |
| Every settings change removes all pending notifications | A new alarm implementation would risk unrelated cancellations | Cancel only owned alarm IDs |
| Settings decoding silently falls back | Corruption can hide user state | Explicit storage errors |
| No alarm model, CRUD, firing UI, tests, or shared scheme | The alarm proposal is not a runnable feature | New app, portable domain, tests, and CI |
| Proposed maximum-volume manipulation, purchases, and background modes | Unnecessary complexity and platform risks | Follow system volume and omit monetization |

## Architecture

`AlarmCore` owns validated records, weekday selection, next-occurrence calculations, storage, and a store tested through a scheduler protocol. The SwiftUI app owns presentation and AlarmKit/AVFoundation adapters. Persist desired state before system mutation and reconcile observed system state; surface failures instead of pretending that disk and system scheduling are one transaction.

AlarmKit on iOS 26 is the minimum target because this product needs real alarms while suspended or terminated. Use a custom PCM chime and speech clip in `Library/Sounds`; no runtime speech callback is required at alarm delivery. A preview uses the same generated clip. Clock and Timer share the natural-English phrase engine and foreground interval scheduler. Background speech remains behind the device spike decision gate.

Snooze is a separate fixed-date alarm initiated in the app. The system alert offers an Open action to reach controls. Timer countdowns include the required Live Activity widget extension.

## Visual direction

Follow the [Halo Ramp reference](design/halo-ramp-reference.html): Clock / Alarm / Timer, serif ring times, floating controls, and continuously blended OKLCH skies. Use the permitted New York/SF system font alternatives. About opens as a sheet from Clock's info button. Text, accent and panel tokens switch atomically at luminance thresholds; only sky colors ease.

## Milestones

1. Establish the three-tool specification and consolidate the native Mac workstream into #7.
2. Implement shared phrases, interval boundaries, timer state, 2–15 minute snooze migration and failure-path tests.
3. Run the physical-device background speech spike and record the decision before implementing a production background session or its Live Activity.
4. Implement the Halo Ramp screens, snoozed sub-rows, confirmations, About and custom timer picker.
5. Implement AlarmKit countdown completion and the required widget extension. Verify spoken final alerts and ringing-loop duration on hardware.
6. Build the native Mac adapter and desktop target only after establishing its separate lifecycle/delivery contract.
7. Run formatting, portable tests, simulator build/launch, reference contrast audit, accessibility checks, and physical-device acceptance.
8. Complete release assets, policy publication and signing. See [delivery investigation](delivery-investigation.md) for implemented work and unresolved gates.

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

- Keep Clock running for at least an hour locked, then with music, silent switch and Bluetooth; record expected versus actual boundaries and other-audio restoration.
- Run Timer presets/custom lengths, pause/resume/reset/restart, and verify its final alert after force-quit.
- Confirm cancel-snooze never changes its parent and changing snooze length never moves a pending snooze.
- Compare 07:00, 12:00, 18:50 and 23:00 light/dark screenshots with the reference.

## Primary references

- [AlarmKit overview](https://developer.apple.com/documentation/alarmkit)
- [Apple's scheduling sample](https://developer.apple.com/documentation/alarmkit/scheduling-an-alarm-with-alarmkit)
- [Custom alert sounds](<https://developer.apple.com/documentation/activitykit/alertconfiguration/alertsound/named(_:)>)
- [Writing synthesized speech to audio buffers](<https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer/write(_:tobuffercallback:)>)
