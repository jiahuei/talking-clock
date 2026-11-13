# Release checklist

The implementation is not yet an App Store release. Physical-device delivery tests, final artwork, and signing remain release gates.

Follow the [App Store publishing guide](docs/app-store-publishing.md) for detailed MacBook setup, account/signing configuration, assets, TestFlight, review, and publication steps. Check items only after recording their results.

## Set up and verify your MacBook

- [ ] Install a compatible released Xcode 26+ and an iOS 26+ simulator runtime; complete first launch and verify the selected Xcode, Swift, and SDK versions using [Mac toolchain setup](docs/app-store-publishing.md#2-install-the-mac-toolchain). Check for a `DEVELOPER_DIR` override when switching installations.
- [ ] Clone the repository and open the root `TalkingClock.xcodeproj`, not the archived project under `v0/`, following [project setup](docs/app-store-publishing.md#4-clone-and-configure-this-project).
- [ ] Run `swift test` and the unsigned simulator build in [local verification](docs/app-store-publishing.md#5-build-and-test-locally) on your Mac. Run the documented formatting checks and record the source commit and toolchain versions. The app scheme has no test target; use the package command.
- [ ] Run the app in iPhone and iPad simulators and exercise the alarm editor, voice preview, clock, and About screen.

The [recorded CI run](https://github.com/jiahuei/ios-talking-clock/actions/runs/39539682750) established an earlier build baseline. It does not complete your local setup or verify a later release candidate. Compilation and simulator testing can be completed before paid membership; publication and TestFlight require it.

## Prepare the release

- [ ] Activate Apple Developer Program membership, accept agreements, add the account in Xcode, and select the paid signing team using [account setup](docs/app-store-publishing.md#3-enroll-and-connect-your-apple-account).
- [ ] Complete the physical-device acceptance tests in [the plan](docs/implementation-plan.md).
- [ ] Verify custom spoken sounds with the app foregrounded, backgrounded, terminated, and after restart/unlock.
- [ ] Test silent mode, Focus, permission denial/revocation, and system volume.
- [ ] Confirm stop, snooze, repeat schedules, DST, and time-zone behavior.
- [ ] Test accessibility, iPad, landscape, and light/dark appearance.
- [ ] Add final app icon and real screenshots.
- [ ] Configure developer signing, app identifier, and App Store Connect metadata.
- [ ] Review the privacy manifest, privacy policy, and support links against the shipped app.
- [ ] Publish working policy/support pages and add an accessible in-app privacy-policy link.
- [ ] Complete App Store privacy, age-rating, export-compliance, pricing/availability, and applicable trader-status information.

## Distribute and publish

- [ ] Archive, validate, and distribute through TestFlight before submission.
- [ ] Record successful physical-device tests of the exact TestFlight release build.
- [ ] Submit the tested build for App Review and resolve any review findings.
- [ ] Release the approved version and verify the public listing and App Store installation.
