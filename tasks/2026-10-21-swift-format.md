# Swift formatting checks

## Summary

Added the official Swift formatter to the push-only lint workflow using a digest-pinned Swift 6.2.4 container. Strict lint checks cover `Package.swift`, `Sources`, and `Tests`; the archived `v0/` remains excluded. Applied the formatter with four-space indentation and a 120-column line length, and documented check and fix commands.

The iOS build retains `pull_request` alongside pushes to `main` and tags matching `v*`.

Integrated the updated lint workflow and approach-validation guidance from `main`, preserving its action pins, branch-push filter, and Prettier settings.

## Verification

- `swift format lint --strict --recursive Package.swift Sources Tests`: passed in the pinned CI container.
- `swift test --scratch-path /tmp/clock-swift-build`: all 28 tests passed in the same container.
- `npx --yes prettier@3.8.3 --check '**/*.md' '.github/**/*.yml' .prettierrc`: passed.
- `git diff --check`: passed. Confirmed no changes under `v0/`.
- The unsigned simulator build cannot run locally because this environment is Linux; the pull-request iOS workflow supplies macOS build and launch verification.
