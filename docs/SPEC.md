# Talking Clock specification

## Product

A calm, accessible alarm clock for iPhone and iPad on iOS 26+. Alarms ring through the system and optionally announce their scheduled time. No account, purchases, tracking, or server.

## Required behavior

- Create, edit, enable, disable, and delete labeled alarms.
- Choose a local time, one-time or weekly recurrence, and whether the alarm speaks.
- Show the next alarm, a live clock, an empty state, and a useful permission/error state.
- Prepare spoken audio before enabling an alarm; play the same sound in a preview.
- Persist alarms across launches. Reconcile externally dismissed one-time alarms.
- Offer Stop and an in-app snooze that creates a separate one-time alarm without replacing the weekly schedule.
- Respect system time formatting, Dynamic Type, VoiceOver, reduced motion, and light/dark appearance.
- Make denied permissions and scheduling failures visible. Never show a failed schedule as enabled.

## Delivery boundary

AlarmKit manages delivery while the app is closed. The spoken clip announces the configured alarm time; it is not a continuously updating speech engine. A delayed system delivery or daylight-saving adjustment can differ from the recorded time. Snooze prepares a new clip for its new firing time.

An alarm needs system authorization and an audible system alarm volume. The device must be powered on. Validate generated custom sounds on physical iOS hardware before claiming release readiness.

No interval-announcement mode, freemium limit, StoreKit, silent background audio, notification fallback, or volume manipulation in this rewrite.
