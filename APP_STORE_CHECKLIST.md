# Release checklist

The implementation is not yet an App Store release. Physical-device delivery tests, final artwork, and signing remain release gates.

Follow the [App Store publishing guide](docs/app-store-publishing.md) for detailed MacBook setup, account/signing configuration, assets, TestFlight, review, and publication steps. Check items only after recording their results.

- [ ] Install a supported Xcode/macOS toolchain and activate Apple Developer Program membership.
- [x] Compile and test the new app with Xcode 26+ ([CI verification](https://github.com/jiahuei/ios-talking-clock/actions/runs/39539682750)).
- [ ] Complete the physical-device acceptance tests in [the plan](docs/implementation-plan.md).
- [ ] Verify custom spoken sounds with the app foregrounded, backgrounded, terminated, and after restart/unlock.
- [ ] Test silent mode, Focus, permission denial/revocation, and system volume.
- [ ] Confirm stop, snooze, repeat schedules, DST, and time-zone behavior.
- [ ] Record the hour-long background speech spike and choose the production architecture before enabling it.
- [ ] Verify AlarmKit custom-sound duration/replay before exposing 15/30/60-second ringing cadence.
- [ ] Verify Timer countdown Live Activity, pause/resume/reset, and spoken final alert after force-quit.
- [ ] Test accessibility, iPad, landscape, and light/dark appearance.
- [ ] Add final app icon and real screenshots.
- [ ] Configure developer signing, app identifier, and App Store Connect metadata.
- [ ] Review the privacy manifest, privacy policy, and support links against the shipped app.
- [ ] Publish working policy/support pages and add an accessible in-app privacy-policy link.
- [ ] Complete App Store privacy, age-rating, export-compliance, pricing/availability, and applicable trader-status information.
- [ ] Archive, validate, and distribute through TestFlight before submission.
- [ ] Record successful physical-device tests of the exact TestFlight release build.
- [ ] Submit the tested build for App Review and resolve any review findings.
- [ ] Release the approved version and verify the public listing and App Store installation.
