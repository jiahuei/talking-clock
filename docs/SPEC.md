# Talking Clock specification

## Product

A calm, accessible talking clock for iPhone and iPad on iOS 26+, with three tools: Clock, Alarm and Timer. Each can speak its time aloud at an interval chosen by the user, including while the screen is locked and the app is in the background. No account, purchases, tracking, or server.

## Required behavior

### Clock

- Show the live time, date and the spoken phrase. Speak the time on demand.
- Speak the time at a chosen interval (every 5 minutes, 15 minutes, 30 minutes, 1 hour, or off), aligned to the clock (for example :00, :05, :10 … for 5 minutes; :00, :15, :30, :45 for 15 minutes).
- Interval announcements continue with the screen locked and the app in the background until the user turns them off.
- Show when the next announcement will happen.

### Alarm

- Create, edit, enable, disable, and delete labeled alarms.
- Deleting an alarm always asks for confirmation first, from every place it can be deleted (swipe, context menu, editor). The prompt names the alarm, and the destructive button says "Delete alarm".
- Cancelling a snooze removes only the temporary snoozed copy; the alarm it came from keeps its settings, schedule and enabled state. Present it as "Cancel snooze", not as deleting an alarm, and ask for confirmation, because a mistaken tap means the alarm won't sound again.
- Choose a local time, one-time or weekly recurrence, and whether the alarm speaks.
- While an alarm rings, play the alarm tune and speak the alarm time at a chosen interval (every 15 seconds, 30 seconds or 1 minute) until Stop or Snooze.
- Show the next alarm, an empty state, and a useful permission/error state.
- Prepare spoken audio before enabling an alarm; play the same sound in a preview.
- Persist alarms across launches. Reconcile externally dismissed one-time alarms.
- Offer Stop and an in-app snooze that creates a separate one-time alarm without replacing the weekly schedule.
- Snooze length is set per alarm, from 2 to 15 minutes in 1-minute steps, defaulting to 9.

### Timer

- Set a duration from presets (1, 5, 10, 25 minutes) or any custom length from 1 second to 23 hours 59 minutes 59 seconds. Start, pause, resume and reset.
- While running, speak the remaining time at a chosen interval (every 30 seconds, 1 minute or 5 minutes), including with the screen locked and the app in the background.
- At zero, alert with the tune and "Time's up" through the system, even if the app has been suspended or closed.

### All tools

- Announcements duck other audio briefly, like navigation voice prompts, and play through the current audio route.
- While Clock or Timer announcements are active in the background, show a Live Activity with the next announcement and a stop control.
- Respect system time formatting, Dynamic Type, VoiceOver, reduced motion, and light/dark appearance.
- Make denied permissions and scheduling failures visible. Never show a failed schedule as enabled.

## Delivery boundary

Alarms and the timer's final alert are delivered by AlarmKit while the app is closed. The alarm's spoken clip announces the configured alarm time at the chosen interval; it is prepared in advance and does not update while ringing. A delayed system delivery or daylight-saving adjustment can differ from the recorded time. Snooze prepares a new clip for its new firing time.

Clock and Timer interval announcements are produced by the app while a speaking session is active, in the foreground or the background. If the user force-quits the app, interval announcements stop; the timer's final alert still fires.

An alarm needs system authorization and an audible system alarm volume. The device must be powered on. Validate generated custom sounds and background announcements on physical iOS hardware before claiming release readiness.

No freemium limit, StoreKit, or volume manipulation in this rewrite.

## Delivery verification and desktop scope

This is the target product contract from issue #7, not a claim of completed device verification. See [delivery investigation](delivery-investigation.md) for the background-audio decision gate and implementation status.

Issue #4 is consolidated into #7 as the native macOS workstream. The three tools, phrases, snooze rules and Halo Ramp design above take priority over the earlier alarm-only brief. Reuse portable AlarmCore code, but establish native Mac scheduling separately; do not assume iOS AlarmKit support. Desktop scope includes keyboard navigation, VoiceOver, local persistence, a menu-bar/launch-at-login evaluation, and documented sleep, window-close, quit, restart and missed-alarm behavior.
