# App Store publishing guide

## Summary

Added a detailed first-release guide covering MacBook/Xcode setup, developer enrollment, signing and app identity, local and device testing, icons and screenshots, privacy and store metadata, archive/upload, TestFlight, App Review, and manual publication. Linked it from the README, development guide, and expanded release checklist.

Documented the current icon and in-app privacy-policy-link gaps, the project's actual bundle/version settings, and the distinction between CI verification and a signed release. Checked Apple requirements against primary documentation on 2026-10-21.

Updated local `main` after PR #2 merged and removed its local implementation branch.

## Verification

- Checked relative documentation links/anchors and parsed shell examples with `bash -n`; passed. Examples were not executed as a release procedure.
- Cross-checked the bundle identifier, version/build, deployment target, signing, shared scheme, missing assets, privacy manifest, and About-screen links against repository files.
- `npx --yes prettier@3.8.3 --check '**/*.md' '.github/**/*.yml' .prettierrc`: passed.
- `swift format lint --strict --recursive Package.swift Sources Tests`: passed in the workflow's pinned Swift 6.2.4 container.
- `git diff --check`: passed. No app, test, workflow, or archived prototype code changed.
- Mac setup, device tests, signed archive, TestFlight upload, and App Store publication were not performed; this documentation change was prepared in a Linux environment without the publisher's Apple account or devices.
