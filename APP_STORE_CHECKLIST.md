# Release checklist

The implementation is not yet an App Store release. Physical-device delivery tests, final artwork, and signing remain release gates.

- [x] Compile and test the new app with Xcode 26+ ([CI verification](https://github.com/jiahuei/ios-talking-clock/actions/runs/39539682750)).
- [ ] Complete the physical-device acceptance tests in [the plan](docs/implementation-plan.md).
- [ ] Verify custom spoken sounds with the app foregrounded, backgrounded, terminated, and after restart/unlock.
- [ ] Test silent mode, Focus, permission denial/revocation, and system volume.
- [ ] Confirm stop, snooze, repeat schedules, DST, and time-zone behavior.
- [ ] Test accessibility, iPad, landscape, and light/dark appearance.
- [ ] Add final app icon and real screenshots.
- [ ] Configure developer signing, app identifier, and App Store Connect metadata.
- [ ] Review the privacy manifest, privacy policy, and support links against the shipped app.
- [ ] Archive, validate, and distribute through TestFlight before submission.
