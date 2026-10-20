# Swift and iOS conventions

- Use SwiftUI and Observation for presentation, Foundation for the portable core, AlarmKit for scheduling, and AVFoundation for audio.
- Keep domain code independent of UI and Apple-only alarm/audio frameworks. Test it with Swift Package Manager.
- Use value types for alarm records, stable UUIDs for schedules, and explicit errors for invalid records.
- Isolate the observable store and system adapters to the main actor. Serialize user mutations so scheduling and persistence do not race.
- Persist a recoverable desired record before changing system state; retain errors and reconcile against actual system registrations.
- Generate a bounded PCM sound in `Library/Sounds`, complete the file before scheduling it, and never delete an audio file while an alarm may reference it.
- Prefer fixed-date schedules for snoozes and calendar-relative schedules for regular alarms.
- Keep snooze identifiers separate from the parent alarm, and cancel child snoozes when disabling/deleting their parent.
- Use built-in controls, semantic fonts/colors, accessible labels, and layouts that survive large text.
- Tests should explain their purpose and cover failures as well as success. Use deterministic clocks/calendars and fake scheduling.
- Keep signing teams, provisioning profiles, and credentials out of the repository. Commit a shared scheme.
