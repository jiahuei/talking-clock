# Halo Ramp delivery investigation

## Status and decision gate

Issue [#7](https://github.com/jiahuei/talking-clock/issues/7) is the product contract; [#4](https://github.com/jiahuei/talking-clock/issues/4) is consolidated into its native macOS workstream. This implementation is a draft, not a verified background-speaking release.

The Linux environment can execute AlarmCore tests and inspect the reference in Chromium. It cannot run Xcode, an iPhone, or a native Mac app. No physical-device spike result has been obtained. Production background announcements and their Live Activity must remain gated until the required hour-long experiment succeeds. Foreground interval speech and system timer completion can be developed independently of that decision.

## API evidence

- Apple's [AlarmKit overview](https://developer.apple.com/documentation/alarmkit) lists iOS/iPadOS 26 and Mac Catalyst; it does not list native macOS. A Catalyst build is not evidence of a native Mac delivery contract.
- The [AlarmKit sample](https://developer.apple.com/documentation/alarmkit/scheduling-an-alarm-with-alarmkit) requires a widget extension for countdown presentations and warns that alarms may otherwise be dismissed without alerting. The timer includes an embedded countdown widget.
- [Custom alert sound names](<https://developer.apple.com/documentation/activitykit/alertconfiguration/alertsound/named(_:)>) resolve in the bundle or Library/Sounds. That page does **not** specify a maximum duration or promise continuous replay. Apple's [notification sound documentation](https://developer.apple.com/documentation/usernotifications/unnotificationsound) imposes a below-30-second limit on notification sounds; this is not proof that AlarmKit supports a 60-second speech cadence.
- [Voice prompt mode](https://developer.apple.com/documentation/avfaudio/avaudiosession/mode-swift.struct/voiceprompt) supports navigation-style speech routing. Ducking and interrupting spoken audio are documented options. A playback session and background mode permit ongoing playback; neither documents a right to resume arbitrary speech after a silent 15-minute suspension.

## Implemented independently of the gate

- Shared English clock, alarm-label and remaining-duration phrases; calendar-aligned clock boundaries and remaining-time timer multiples.
- Clock, Alarm and Timer screens, About sheet, natural time displays, and the reference's OKLCH sky and contrast tokens. Uses the reference's permitted New York/SF system font substitutes.
- Foreground interval announcements. Clock starts off until the user chooses an interval. Leaving the foreground stops the announcement tasks; returning recomputes future boundaries without replaying missed speech.
- AlarmKit timer completion with a prepared "Time's up" sound, countdown widget and Stop control. Pause, resume and reset operate on the system timer before updating the local presentation. A stable dedicated timer identifier makes Reset possible after UI-state loss.
- Snooze migration from document version 1 to 2, including pending journal snapshots. Values valid under the old 1–30 contract clamp to 2–15; corrupt values are rejected and preserved. Editing an enabled parent leaves its already scheduled snooze intact.
- Named delete confirmations and separate cancel-snooze confirmations. Cancelling a child preserves its parent.
- Local in-app privacy text; the public policy URL still requires publication and review before submission.

## Running the isolated device spike

In Xcode, use the Debug configuration and add `-BackgroundSpeechSpike` to the scheme's launch arguments. The separate Debug plist declares audio background mode; the Release plist does not. The regular app does not start the experiment. Tap **Start 70-minute experiment** explicitly. It prepares fourteen five-minute boundary phrases, schedules them on an AVAudioEngine speech node, and runs a separate continuous silent buffer between them. It uses mixed playback between announcements and toggles ducking for each phrase. These exact mechanics are experimental, including whether changing session options preserves the running engine and restores podcasts correctly.

A Live Activity shows the next announcement and a Stop control. Stop opens the host app and signals the isolated controller; also test it while the device is locked. The programme stops after its last clip. There is no automatic replenishment, relaunch restart, notification fallback, or production background feature dependent on this spike. Interruption and route-change behavior must be measured and designed after the experiment; this harness does not claim recovery guarantees.

Record results in the PR before integrating a full session. Remove the launch argument to return to the regular app. A successful build of this harness is not a passing spike.

## Outstanding acceptance gates

- Run the section 3 continuous-programme spike for at least an hour locked, then repeat with music, silent switch and Bluetooth. Record model, OS/build, expected/actual announcement times, interruption handling, route changes and restoration of other audio. Do not interpret a simulator pass as evidence.
- Decide the production background architecture from those results; implement the user-started session and its next-announcement/Stop Live Activity only after that decision. A notification fallback requires an explicit product decision because its behavior differs.
- Verify actual AlarmKit sound duration and replay behavior for 15/30/60-second cadence on supported OS versions. Until then, the app retains a bounded tune-plus-phrase clip and does not expose a cadence setting it cannot honor.
- Compare native screenshots at 07:00, 12:00, 18:50 and 23:00 in both appearances. Validate accessibility sizes, VoiceOver focus, Reduce Motion, iPad, landscape and 12/24-hour settings.
- Validate the final timer alert and its sound after suspension, force-quit, restart/unlock, and system cancellation. Validate external pause/resume reconciliation from AlarmKit Live Activity timing, including devices where Live Activities are disabled or their timing is temporarily unavailable.
- Publish the privacy-policy URL and link it from About before App Review.

## Native macOS workstream from #4

Minimum OS and scheduling APIs remain undecided pending a Mac experiment. Preserve AlarmCore and provide a separate native scheduling/audio adapter. Do not substitute an in-process timer or notification for an iOS AlarmKit alarm or advertise unverified quit/sleep delivery on Mac.

Evaluate native UserNotifications for visible system delivery and AVFoundation for speech while running; document any silent-mode/Focus, custom-sound, repeat, and audio-route limits. Evaluate a menu-bar entry point and optional ServiceManagement login item only after choosing the lifecycle contract. Closing a window must be distinguished from quitting the process.

Before shipping the desktop workstream:

- Specify whether a missed alarm is surfaced, skipped, or rescheduled after sleep/relaunch, with no accidental re-arming.
- Implement the shared three-tool behavior with native keyboard access, VoiceOver, local recoverable persistence, and Halo Ramp light/dark layout.
- Add a native macOS target, build/launch CI and signing instructions.
- Test window closure, minimization, lock, quit, sleep/wake, restart, permission changes, muted audio, Focus, headphones/Bluetooth and output changes on a real Mac.
- Retain calendar/DST/time-zone and scheduling/persistence failure tests; verify edits remove obsolete schedules and snoozes preserve repeats.

The macOS checklist is intentionally not marked implemented by this iOS PR.
