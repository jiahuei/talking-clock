# Guide for AI agents

This repository builds Talking Clock, a native iOS alarm clock that speaks the alarm time. Adapted from the engineering workflow in [Travel Plan's foundation PR](https://github.com/jiahuei/travel-plan/pull/2).

## Layout and scope

- `v0/` preserves the original interval clock and unimplemented alarm proposal. Treat it as a read-only reference.
- Read `docs/implementation-plan.md`, `docs/SPEC.md`, and `docs/CONVENTIONS.md` before changing the app.
- The new app lives in `Sources/TalkingClock/`, with portable domain code in `Sources/AlarmCore/` and tests in `Tests/AlarmCoreTests/`.
- The new application is implemented; physical-device verification remains a release gate.

## Engineering workflow

- Understand the concrete problem before editing. Prefer system frameworks and straightforward code over dependencies and abstractions.
- Plan substantial work, proceed within the user's authorization, and revise the plan when evidence changes.
- Preserve uncommitted work. Never use destructive Git operations without explicit authorization.
- Keep changes focused. Review the final diff for correctness, data integrity, unnecessary complexity, and stale documentation.
- Do not delegate unless the user or governing instructions authorize it.
- Implement fixes through their root cause. Surface permission, persistence, audio, and scheduling failures to the user.
- Add regression coverage for meaningful behavior and edge cases. Document each test's purpose.
- Never claim a check passed unless it ran. Distinguish simulator builds, unit tests, and physical-device validation.
- At completion, add a dated `tasks/YYYY-MM-DD-<task>.md` record with `## Summary` and `## Verification`.
- Record only durable project lessons; avoid turning conversational preferences into permanent rules.

## Platform invariants

- Use AlarmKit for system alarms. An in-process timer or local notification is not an equivalent alarm.
- Prepare spoken audio before scheduling. App code is not guaranteed to execute when a background alarm rings.
- Do not keep the app alive with silent audio, force system volume, request unrelated permissions, or promise critical alerts.
- An alarm is enabled only after successful scheduling. Keep failed edits recoverable; never silently replace a working alarm with an unscheduled one.
- Use calendar arithmetic for wall-clock alarms, inject dates/calendars in domain tests, and cover DST and week rollover.
- Keep alarm identifiers stable, preserve repeat schedules when snoozing, and reconcile persisted records with the system.
- Do not introduce purchases, accounts, analytics, cloud services, or network dependencies without a product requirement.

## Verification

`.github/workflows/lint.yml` is the formatting source of truth:

```sh
npx --yes prettier@3.8.3 --check '**/*.md' '.github/**/*.yml' .prettierrc
git diff --check
```

Once runtime code exists, run `swift test` and the iOS build command documented in `QUICKSTART.md`. Add these checks to CI. Use Xcode 26 or later for AlarmKit. A Linux environment cannot compile Apple-only frameworks. Do not reformat archived `v0/` code. Keep dependency lockfiles trackable and tool versions pinned where practical.

## Code and review conventions

- Use clear names, small types, and explicit ownership of state.
- Explain non-obvious platform constraints in comments; do not narrate obvious code.
- Keep UI state on the main actor. Isolate system integrations behind testable interfaces.
- Never log personal alarm labels or speech content.
- Read current Apple documentation when changing framework integrations.
- Review remote main's recent commit subjects before selecting a PR title.
- PR descriptions start with `## Summary`, explain the problem and resulting behavior, and include `## Verification` with actual results and limitations.
- Update the entire PR description when scope changes. Do not merge or release unless requested.
