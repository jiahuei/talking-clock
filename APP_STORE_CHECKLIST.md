# Release checklist

The repository foundation is not an App Store release.

- [ ] Compile and test the new app with Xcode 26+.
- [ ] Complete the physical-device acceptance tests in [the plan](docs/implementation-plan.md).
- [ ] Verify custom spoken sounds with the app foregrounded, backgrounded, terminated, and after restart/unlock.
- [ ] Test silent mode, Focus, permission denial/revocation, and system volume.
- [ ] Confirm stop, snooze, repeat schedules, DST, and time-zone behavior.
- [ ] Test accessibility, iPad, landscape, and light/dark appearance.
- [ ] Add final app icon and real screenshots.
- [ ] Configure developer signing, app identifier, and App Store Connect metadata.
- [ ] Review the privacy manifest, privacy policy, and support links against the shipped app.
- [ ] Archive, validate, and distribute through TestFlight before submission.
