# Guide for AI agents

This file guides agents working on Talking Clock, a native iOS alarm clock that speaks the alarm time.

Adapted with minimal project-specific changes from [Travel Plan](https://github.com/jiahuei/travel-plan/blob/main/AGENTS.md), originally adapted from [EmbeddedLLM/agent-game](https://github.com/EmbeddedLLM/agent-game/blob/819dc8b86cfab9d2e017db8fd9fce70de00491af/AGENTS.md). Retain its engineering workflow and review conventions while replacing travel-app-specific runtime requirements.

## Project Status and Layout

This foundation contains planning and configuration for the new app, with the original prototype archived in `v0/`. The application paths and commands below are implementation targets until their manifests and source files exist. Do not report the application as implemented or runnable before then.

- `docs/implementation-plan.md`: product scope, architecture, milestones, and acceptance criteria.
- `Sources/TalkingClock/`: SwiftUI screens and AlarmKit/AVFoundation adapters.
- `Sources/AlarmCore/`: portable Swift domain, calendar calculations, persistence, and alarm state.
- `Tests/AlarmCoreTests/`: domain and failure-path tests.
- Read `docs/SPEC.md` and `docs/CONVENTIONS.md` before implementing the app.
- `v0/` is the original interval clock and alarm proposal. Preserve it unchanged and use synthetic alarms in committed tests, screenshots, and documentation.

The user's job as a senior software engineer is dependent on you implementing clean code with elegant architecture.

## Core Principles

- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Simplicity First**: Make every change as simple as possible. Only touch what's necessary. Impact minimal code. Over-complication leads to bugs.
  1. Always start with thorough understanding of the problem and motivation
  2. Does this functionality need to exist? → no: challenge or skip it (YAGNI)
  3. Already in this codebase? → reuse or extend it, don't rewrite
  4. Stdlib does it? → use it
  5. Native platform feature? → use it
  6. Installed dependency? → use it
  7. One line? → one line
  8. Only then: the minimum that works
- **Validate the Approach Before Implementing**: For non-trivial changes, distinguish the required outcome from the proposed implementation. Treat suggestions, including those in issues and plans, as hypotheses to validate.
  1. Identify the required behavior and existing state that must be preserved.
  2. Check existing code and native platform capabilities for a solution that requires less change.
  3. Resolve uncertain behavior through authoritative documentation or a focused experiment before coding.
  4. Require evidence that a simpler approach is insufficient before adding complexity or performing a destructive operation.
  5. Derive tests from required behavior and preservation requirements rather than assumptions about the implementation.

  Keep this proportional: straightforward changes do not need a written alternatives analysis.

- **Simplify After Implementation**: Treat the first working version and the requirements behind it as drafts.
  1. Run relevant tests to uncover hidden requirements and assumptions.
  2. Relate every code path back to a concrete requirement, and challenge whether that requirement is truly necessary (first principles approach).
  3. Review the full diff for unnecessary abstractions, branches, defensive code, and overly strict guarantees.
  4. Match guarantees to the domain. Alarm authorization, persistence, and system scheduling require consistent state; use simple retries only when they cannot duplicate or unexpectedly re-arm an alarm.
  5. Remove or relax requirements that do not justify their complexity. Simplify immediately when behavior is preserved; otherwise present the proposed change, benefits, and trade-offs to the user.
- **Protect Secrets in Command Output**: Do not print signing credentials, provisioning secrets, or personal alarm labels and speech content in command output.

## Workflow Orchestration

### 1. Planning

- For non-trivial work, create a concise implementation plan before editing.
- Proceed without waiting for approval when the requested outcome is clear and the changes are low-risk.
- Ask for clarification only when ambiguity would materially change behavior, public interfaces, data, security, or architecture.
- Re-plan when evidence invalidates the current approach.
- Keep planning proportional to the task; do not create process overhead for straightforward changes.

### 2. Task Boundaries

- Keep research and implementation tasks bounded and aligned with the current request.
- Use parallel agents only when authorized by the user or governing environment instructions.
- Implement the authorized task scope. Treat deployment as separate from a request to implement code or open a PR.

### 3. Task Tracking

- Use `tasks/todo.md` for substantial, multi-stage work when persistent tracking is useful.
- Do not create or modify `tasks/todo.md` for small or routine changes; the completion record below is still required.
- At the end of every feature, bug fix, or task, before the final handoff, create `tasks/YYYY-MM-DD-<task-name>.md`. Use the completion date and a short, descriptive, lowercase task name with hyphens.
- Write the completion record using the structure and wording rules in [PR Descriptions](#pr-descriptions).
- Record only durable, project-specific lessons in `tasks/lessons.md`.
- Do not record one-off user preferences, speculative conclusions, or conversational details.
- A user correction is evidence to reconsider the approach, not an automatic reason to create a permanent rule.

### 4. Verification Before Done

- Run the strongest applicable verification available in the current environment.
- Never claim that a check passed unless it was actually run and passed.
- When a check cannot be run, report the exact command not run and the reason.
- Distinguish failures introduced by the current change from pre-existing or environment-dependent failures.
- Verify the behavior affected by the change, not merely that the code compiles.
- Add or update regression tests when fixing a reproducible defect.
- All tests must have docstrings stating their intention, goal, purpose, or the regression they guard against. For example: "Ensures ..." or "Asserts that ...".
- Compare behavior before and after the change when practical.
- Run the applicable checks defined in the Linting Workflow.
- Always check whether any project documentation needs updating, even when documentation was not mentioned in the task. Update all affected docs before reporting completion.
- Keep verification proportional to the scope and risk of the change.

#### Local development environment

- Use Xcode 26+ and Swift Package Manager for the iOS 26+ app. Keep dependency lockfiles trackable when created.
- Run development commands from the repository root; see `QUICKSTART.md` for signing and device setup.
- Once the package exists, run `swift test`.
- Keep persistence tests isolated in temporary directories and exercise scheduling failures through test doubles.
- Once the app exists, run `xcodebuild -project TalkingClock.xcodeproj -scheme TalkingClock -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath build CODE_SIGNING_ALLOWED=NO build` on macOS.
- Validate locked/background/terminated alarm delivery and custom spoken sounds on a physical device. Linux cannot compile Apple-only frameworks.
- Do not import the reference application's backend, frontend, database, or container stack without a concrete iOS-app requirement.

Before reporting completion, review the final diff for correctness, unnecessary complexity, and verification evidence.

### 5. Demand Elegance (Balanced)

- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes – don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing

- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests – then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

### 7. Task Management

1. **Plan First**: Use `tasks/todo.md` for substantial work when persistent tracking is useful.
2. **Verify Plan**: Check the plan against the authorized scope; proceed when the outcome is clear.
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Create the dated completion record in `tasks/` using the required [PR description format](#pr-descriptions).
6. **Capture Lessons**: Record durable project lessons when justified, not every correction.

### 8. Linting Workflow

- Run formatting, linting, and static analysis after implementation and before reporting completion.
- The `.github/workflows/lint.yml` workflow is the source of truth. Before running checks, inspect it and use the commands, installation method, configuration, and tool versions selected by that workflow. Do not substitute globally installed tools; keep the foundation command below synchronized with CI until runtime manifests own the tooling.
- Start with changed files for fast feedback, then run the applicable repository-wide checks used by CI.
- When editing or creating Markdown files, run every applicable formatting or linting checks.

The push-only documentation CI runs `npx --yes prettier@3.8.3 --check '**/*.md' '.github/**/*.yml' .prettierrc`. Use that exact version for formatting this foundation. It needs registry access if not cached.

Add Swift package tests and iOS build checks to CI as their manifests and implementations land. The application commands below apply after that bootstrap; do not run or claim checks against nonexistent code. Request additional execution permissions only when the environment requires them.

Do not format unrelated files merely to make a repository-wide check pass.

#### Swift and iOS

From the repository root, once the implementation exists:

1. Inspect the test and build steps in `.github/workflows/ios.yml`.
2. Select the Xcode/Swift toolchain used by that workflow.
3. Confirm the selected versions: `xcodebuild -version` and `swift --version`.
4. Run `swift test` for the portable domain and persistence logic.
5. Run the unsigned simulator build command above and the launch smoke check configured in CI.
6. Record physical-device verification separately; a simulator build does not prove alarm sound delivery.

Do not format unrelated files merely to make a repository-wide check pass. Do not reformat the archived `v0/` code.

#### Failure Handling

- When a project-wide check fails, rerun the narrowest relevant command to determine whether the failure was caused by the current change.
- Fix failures introduced by the current change.
- Do not modify unrelated code to resolve pre-existing failures.
- Report pre-existing, infrastructure-dependent, or environment-dependent failures with the exact command and relevant error.
- Never describe a skipped, incomplete, or failing check as passing.
- In the final handoff, list the verification, test, formatting, linting, and static-analysis commands run, together with their outcomes.

### 9. Repository Safety

- Inspect `git status` and the relevant diff before editing.
- Preserve existing uncommitted changes and never overwrite work you did not create.
- Do not use destructive Git commands such as `reset --hard`, `clean`, or broad checkout/restore operations unless explicitly requested.
- Do not commit, push, create branches, or open pull requests unless requested.
- Avoid modifying generated files unless the project workflow requires regeneration.
- Keep unrelated formatting, refactors, dependency updates, and lockfile changes out of the diff.

## Closing Issues

- Before closing an issue as completed, review its requirements, the merged changes, and the current source on `main` to confirm it is fully resolved.
- Leave a brief closing comment stating where the fix is available, summarizing the resulting behavior, and linking the merged PRs and commit URLs. State what was verified and any remaining limitations.
- Close as completed only when the issue is resolved. For duplicates, superseded work, or declined requests, explain the reason and link the replacement issue when applicable.

## PR Descriptions

- Use the structure below for GitHub PR descriptions and dated task completion records.
- Start PR descriptions with `## Summary`; do not repeat the PR title in the description. Dated task completion records should prepend a `# <task title>` heading.
- Before choosing a PR title, review the latest commits on the remote main branch (`git fetch origin main`, then `git log origin/main -10 --format=%s`) and follow the style of comparable changes, preferring area prefixes found in that history.
- Use declarative statements to describe completed changes, their purpose, and resulting behavior. For example "Replaced ..." or "The workflow now uses ...".
- Lead with the concrete problem and resulting behavior. Write for a reviewer who has not read the conversation, and keep details proportional to the change.
- Keep the title and description aligned with the final diff. Omit conversational history and abandoned approaches unless they explain a necessary trade-off.
- When updating a PR, review and rewrite the Summary section as needed to reflect the latest state of the entire PR. Do not merely append a bullet for each new commit pushed; consolidate or remove outdated bullets so the summary describes the current changes coherently.
- List verification commands and their actual outcomes. Include failed or skipped checks and their reasons; never claim an unrun check passed. Distinguish completed implementation from unverified deployment or runtime behavior.

```markdown
## Summary

- <Completed change and its purpose>

## Verification

- `<command>`: <outcome, or reason it was not run>
```

## Coding Conventions

### General Conventions

- When writing prompts, avoid using non-ASCII symbols.
- Follow the existing code style in each file.
- Use meaningful variable and function names.
- **Pin dependency versions**: Use exact versions (e.g. `.exact("2.0.0")`) for dependencies in `Package.swift`. Never use open-ended version ranges.

### Code Comments

- Prefer clear code, meaningful names, and straightforward structure over comments that merely describe what the code does.
- Add comments when the reason behind an implementation would not be obvious to another developer.
- In particular, comment logic that:
  - may be surprising or counter-intuitive;
  - encodes a business rule or architectural decision;
  - intentionally deviates from established conventions or the most obvious implementation;
  - reflects an accepted trade-off, limitation, workaround, or compatibility constraint;
  - depends on subtle assumptions, ordering requirements, external behaviour, or non-obvious invariants;
  - is sufficiently complex that its intent or correctness would otherwise be difficult to verify.

- Comments should explain **why** the implementation exists, what constraint or decision led to it, and — when useful — what could go wrong if it is changed.
- Do not add comments that simply restate the code, narrate each operation, or compensate for unnecessarily complicated implementation.
- Keep comments accurate when modifying the associated code. Remove comments that are obsolete, misleading, or no longer useful.

### Swift and iOS Conventions

Before working on the app or its domain code, read and follow `docs/SPEC.md` and `docs/CONVENTIONS.md`.

## Code Review and Refactoring Guidelines

- Ask reviewers to challenge the necessity of the proposed mechanism and identify simpler existing alternatives, as well as checking correctness.
- Prioritize correctness, security, data integrity, and behavioral regressions.
- Identify duplicated logic, unnecessary branches, and avoidable complexity.
- Keep variant-specific behavior in explicit, responsibility-focused paths.
- Place genuinely shared validation, state updates, processing, and finalization in one location.
- Preserve observable behavior, ordering, errors, and public interfaces unless a change is explicitly requested.
- Prefer straightforward control flow over premature helper abstractions.
- Ensure abstractions reduce cognitive load rather than merely moving code.
- Touch only code relevant to the review or refactor.
- Add or update regression tests for every affected path and edge case.
- Review the final diff and confirm the result is materially simpler.
- Always provide concrete findings and recommended solutions.
- Check compliance with this `AGENTS.md` and project conventions.

## Alarm Domain Invariants

- Use AlarmKit for system alarms. An in-process timer or local notification is not an equivalent alarm.
- Prepare spoken audio before scheduling. App code is not guaranteed to execute when a background alarm rings.
- Do not keep the app alive with silent audio, force system volume, request unrelated permissions, or promise critical alerts.
- An alarm is enabled only after successful scheduling. Keep failed edits recoverable; never silently replace a working alarm with an unscheduled one.
- Use calendar arithmetic for wall-clock alarms, inject dates/calendars in domain tests, and cover DST and week rollover.
- Keep alarm identifiers stable, preserve repeat schedules when snoozing, and reconcile persisted records with the system.
- Keep UI state on the main actor. Isolate system integrations behind testable interfaces.
- Read current Apple documentation when changing framework integrations.
- Do not introduce purchases, accounts, analytics, cloud services, or network dependencies without a product requirement.
