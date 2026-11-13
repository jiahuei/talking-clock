# Publish Talking Clock on the App Store

This guide takes you from a MacBook without a development environment to a public iPhone/iPad release. Follow the sections in order for the first release; use [the release checklist](../APP_STORE_CHECKLIST.md) to record completion.

Apple documentation was checked on **2026-10-21**. Recheck the linked requirements before uploading: supported Xcode/macOS versions, screenshots, and App Store Connect screens change. The instructions describe work you still need to perform with your own Apple account and devices; a passing GitHub build is not a signed or published app.

## Contents

1. [Current readiness](#1-know-what-is-ready-and-what-remains)
2. [Mac toolchain](#2-install-the-mac-toolchain)
3. [Apple account and enrollment](#3-enroll-and-connect-your-apple-account)
4. [Project and signing setup](#4-clone-and-configure-this-project)
5. [Local and device testing](#5-build-and-test-locally)
6. [Icon, policy, and screenshots](#6-finish-the-icon-policy-and-release-assets)
7. [App Store Connect record](#7-create-the-app-store-connect-app-record)
8. [Listing and compliance](#8-fill-in-the-store-listing-and-compliance-information)
9. [Archive and upload](#9-archive-validate-and-upload)
10. [TestFlight](#10-test-the-uploaded-build-with-testflight)
11. [App Review](#11-submit-for-app-review)
12. [Public release](#12-publish-and-verify-the-public-release)

[Troubleshooting](#troubleshooting) covers common setup, signing, upload, and alarm-delivery failures.

## 1. Know what is ready and what remains

| Item | Current repository state | Your release action |
| --- | --- | --- |
| App | Native SwiftUI/AlarmKit app for iOS/iPadOS 26+ | Test the actual release build on physical devices |
| Xcode project and scheme | `ios/TalkingClock.xcodeproj`, shared `TalkingClock` scheme | Open the project under `ios/`; `v0/` is an archived prototype |
| Bundle identifier | `com.jiahuei.talkingclock` | Confirm your developer team owns it, or choose your own permanent identifier |
| Version / build | `2.0` / `1` in both configurations | Choose the public version and assign a fresh build number for each upload |
| Signing | Automatic signing, no team committed | Select your paid Apple Developer Program team locally |
| App icon | No asset catalog or AppIcon setting yet | Create and configure a final icon before archiving |
| Privacy | Local-only design and bundled privacy manifest | Audit the final binary, publish a policy, and add an in-app policy link |
| About sheet | Support link and local policy text exist; public policy URL is pending | Publish and wire the policy URL before review |
| CI | Formatting, domain tests, unsigned simulator build, launch check | Supply device evidence, signing, upload, and submission yourself |

The recorded voice announces the **scheduled** time in English. It does not update continuously while ringing. Snooze requires opening the app from the system alert. Use these limits consistently in screenshots, descriptions, and reviewer notes.

## 2. Install the Mac toolchain

1. Open **Apple menu > About This Mac** and note your Mac model, chip, and macOS version. Back up the Mac before an OS upgrade. Allow ample disk space for Xcode, simulator runtimes, build products, and archives.
2. Check [Apple's Xcode compatibility table](https://developer.apple.com/xcode/system-requirements/) and [submission requirements](https://developer.apple.com/app-store/submitting/). Choose a released Xcode version supported by your macOS and your test device's OS. This app needs Xcode 26 or later; its CI currently selects Xcode 26.x. The verified Xcode 26.6 environment requires macOS Tahoe 26.2–26.x. If using a newer Xcode, run the checks below rather than assuming the older CI result covers it.
3. Install the full **Xcode** app from the Mac App Store, or download the chosen released version from [Apple Developer Downloads](https://developer.apple.com/download/all/). A downloaded `.xip` expands into an app; move it into `/Applications`. Command Line Tools alone cannot build the iOS app.
4. Launch Xcode, accept its license, and let its initial component installation finish. Install iOS platform support and an iOS 26+ simulator runtime through **Xcode > Settings > Components** (called Platforms in some versions). See [Apple's component installation instructions](https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components).
5. Open Terminal and select this installation. If your app has a versioned name, replace `/Applications/Xcode.app` below with its actual path.

```sh
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
xcode-select -p
xcodebuild -version
xcodebuild -showsdks
xcrun swift --version
git --version
```

The selected path should end in `Xcode.app/Contents/Developer`, not `/Library/Developer/CommandLineTools`. The SDK list must include iOS 26 or later. Swift, Git, the compiler, simulator tools, and Swift Package Manager come with this setup; no CocoaPods or third-party app dependencies are needed.

The SDK you build with and the minimum OS your app supports are separate. Keep this project's deployment target at **26.0** because it uses AlarmKit. Apple's [upload requirements](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/) currently require the iOS 26 SDK or later; its [submission page](https://developer.apple.com/app-store/submitting/) announces iOS 27 SDK requirements starting April 2027. Recheck when you release.

**Checkpoint:** Xcode opens, the commands succeed, and a compatible iPhone simulator appears in the run-destination picker.

## 3. Enroll and connect your Apple account

1. Use an Apple Account with two-factor authentication and enroll in the [Apple Developer Program](https://developer.apple.com/help/account/membership/program-enrollment/). Publishing and TestFlight require membership; a free Personal Team is insufficient. The listed fee is USD 99 per membership year, with regional pricing and possible eligible fee waivers.
2. Choose the correct enrollment type. An individual account publishes under your legal name; an organization account requires a qualifying legal entity and organization verification, generally including a D-U-N-S Number. Complete Apple's identity checks and wait for active membership.
3. Sign in to [App Store Connect](https://appstoreconnect.apple.com/). As Account Holder, accept outstanding agreements. Free distribution is covered by the developer agreement; selling a paid app or adding purchases additionally requires the Paid Apps Agreement and the requested banking/tax setup. See [Apple's agreement guidance](https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements/).
4. In **Xcode > Settings > Accounts**, add that Apple Account and confirm the paid team appears. If someone else owns the team, have them grant the required developer/account access. Uploading and submitting have different roles; an Account Holder can perform this guide end to end.

Keep account credentials, certificate private keys, provisioning files, and App Store Connect API keys out of Git. This manual release process does not require adding signing secrets to GitHub Actions.

## 4. Clone and configure this project

For a new checkout, run:

```sh
mkdir -p ~/Developer
cd ~/Developer
git clone https://github.com/jiahuei/ios-talking-clock.git
cd ios-talking-clock
git switch -c chore/prepare-first-release
open ios/TalkingClock.xcodeproj
```

If the repository is already on your Mac, use that checkout instead. Preserve any local changes, update `main` with `git pull --ff-only`, and create a release-preparation branch before editing.

In Xcode's navigator, select the blue **TalkingClock** project, then the **TalkingClock target**:

1. Under **Signing & Capabilities**, enable **Automatically manage signing** and select your paid team. Allow Xcode to manage the necessary signing assets. Configure both Debug and Release.
2. Set the bundle identifier. Keep `com.jiahuei.talkingclock` only if it belongs to your team. Otherwise use a unique reverse-domain identifier you control, such as `com.yourname.talkingclock`. Confirm both configurations use the same identifier. Choose carefully: it identifies the app in App Store Connect and cannot be changed there after the first build upload. See [distribution preparation](https://help.apple.com/xcode/mac/current/en.lproj/dev91fe7130a.html).
3. Under **General**, retain iPhone and iPad support and minimum iOS 26.0. The shared scheme is named **TalkingClock**. Do not open the similarly named project under `v0/`.
4. Choose the public **Version**. The project starts at `2.0`; that can be your first public version, or you can intentionally change it before the first upload. The App Store Connect version must match it. **Build** starts at `1`; increment it for every replacement upload, even when the public version is unchanged.
5. Check `ios/Configuration/Info.plist`: `NSAlarmKitUsageDescription` is already present. Preserve a clear explanation of why the app needs alarm permission. No microphone or speech-recognition permission is needed for the existing speech-synthesis design.

The repository convention keeps signing team identifiers out of committed project settings. Keep the team selection local and inspect the project diff before committing public changes such as the permanent bundle ID, icon configuration, or version.

**Checkpoint:** the target has no signing errors and its identity, team, version, and deployment target are the ones you intend to ship.

## 5. Build and test locally

From the repository root:

```sh
swift test --package-path ios
xcodebuild -project ios/TalkingClock.xcodeproj -scheme TalkingClock -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
git diff --check
```

`swift test --package-path ios` runs the portable `AlarmCore` suite. The Xcode app scheme does not currently contain a test target, so Product > Test is not a substitute for the package command. The simulator build is deliberately unsigned; do not copy `CODE_SIGNING_ALLOWED=NO` into your device or archive configuration.

For an interactive smoke test, select an iPhone simulator in Xcode and press **Run** (`Command-R`). Add, edit, disable, and delete synthetic alarms; try voice preview, the clock tab, and the About sheet from the Clock screen's i button. Repeat on an iPad simulator and with large text and dark appearance.

Formatting uses the versions in [the lint workflow](../.github/workflows/lint.yml). Install Node.js 24 from the [official Node.js download site](https://nodejs.org/en/download) if you want to run the Markdown/YAML check locally:

```sh
node --version
npx --yes prettier@3.8.3 --check '**/*.md' '.github/**/*.yml' .prettierrc
```

Swift formatting CI uses a pinned **Swift 6.2.4** container, which can differ from the Swift bundled with your selected Xcode. Let the push workflow check it, or reproduce it with Docker if already installed and running:

```sh
docker run --rm \
  --mount "type=bind,source=$PWD,target=/workspace,readonly" \
  --workdir /workspace \
  swift@sha256:d6f8f6112e9a63da0a4a151d6b93acd16699d35c0b82531ac1a245f5af210197 \
  swift format lint --strict --recursive ios/Package.swift ios/Sources ios/Tests
```

With the matching Swift toolchain selected locally, the same `swift format lint --strict --recursive ios/Package.swift ios/Sources ios/Tests` command works directly. Docker and Node are development-check tools, not requirements for archiving or uploading the app. Keep `v0/` excluded.

### Test real alarm delivery on your iPhone and iPad

1. Connect an iOS/iPadOS 26+ device by cable, unlock it, and accept the trust prompt. Select it in Xcode's device picker and let pairing finish. If your device OS is newer than the selected Xcode supports, install a compatible released Xcode.
2. Enable **Settings > Privacy & Security > Developer Mode**, restart, and confirm when asked. Pairing may be needed before the setting appears. This is for development builds; TestFlight/App Store installations do not require it. See [Apple's Developer Mode instructions](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device/).
3. Run from Xcode. Create an alarm a few minutes ahead and grant alarm permission. Confirm voice preview succeeds, then test scheduled delivery with the app closed and the device locked, disconnected from the debugger.
4. Complete the matrix below and [all acceptance tests](implementation-plan.md#acceptance-tests). Repeat the core delivery tests on the later TestFlight build.

| Scenario | What to record |
| --- | --- |
| Foreground, background, force-quit, restart then unlock | Whether the system alarm appears and the correct spoken clip is audible |
| Silent mode, Focus, different system alarm volumes | Actual audibility and any platform limitations |
| Permission denied or revoked | Actionable error and no falsely enabled alarm |
| One-time Stop, edits, disable, delete | No obsolete registration rings later |
| Weekly repeat and in-app snooze | Parent remains scheduled; snooze speaks its own scheduled time |
| Clock/Timer intervals locked for an hour; music, silent switch, Focus, headphones and Bluetooth | Timing, ducking/restoration, route changes, interruptions, next-announcement Live Activity and Stop |
| Timer paused/resumed/reset and final alert after force-quit | Correct remaining time, no obsolete alert, spoken completion |
| Midnight, DST, time-zone changes | Actual delivery compared with the scheduled-time recording |
| iPad, landscape, VoiceOver, largest text, light/dark | Usable controls, readable labels, and no clipped content |

Record device model, OS version, app version/build, steps, and result in a dated release-test record. A preview or simulator launch does not establish locked-device delivery. Fix failures and retest before submitting; leave untested items unchecked.

## 6. Finish the icon, policy, and release assets

### Add the app icon

1. Prepare original artwork you have the rights to use. For the asset-catalog route, use an opaque 1024 × 1024 PNG for the standard iOS App Store icon; let the OS apply its mask rather than baking rounded corners into the image.
2. In Xcode, create an **Asset Catalog** named `Assets.xcassets` under `ios/Sources/TalkingClock/` and ensure it belongs to the TalkingClock target. Add an **App Icon** set named `AppIcon` and fill its required image wells. Use the single-size option if offered; follow Xcode's fields for any appearance variants.
3. In the target's **General > App Icons and Launch Screen**, select `AppIcon` as the app icon source. In Build Settings, confirm **Asset Catalog App Icon Set Name** (`ASSETCATALOG_COMPILER_APPICON_NAME`) is `AppIcon` for Release as well as Debug.
4. Build and run again, check the installed icon, and commit the artwork/catalog and public project setting. Follow [Apple's asset-catalog icon guide](https://developer.apple.com/documentation/xcode/configuring-your-app-icon) if the UI differs. No icon is configured in the current repository.

### Publish policy and support pages

1. Review [PRIVACY.md](../PRIVACY.md) and [SUPPORT.md](../SUPPORT.md) against the final app. Publish readable, stable HTTPS pages that open without authentication. A public repository page can be a starting point; verify it in a signed-out browser and keep the URLs working after release.
2. Provide a monitored contact route and practical support instructions. Explain local alarm storage, generated voice clips, device backups, and how users can remove their data; avoid promises that do not match the shipped app.
3. Add a clearly labeled **Privacy Policy** link to the app's About sheet (`ios/Sources/TalkingClock/ClockView.swift`). Local policy text is present; the public policy URL still needs publication. Apple's [review guidelines, section 5.1.1](https://developer.apple.com/app-store/review/guidelines/#privacy) require an accessible in-app policy link as well as App Store metadata. Test both links on a device.
4. Inspect `ios/Sources/TalkingClock/PrivacyInfo.xcprivacy`. It currently declares no tracking, collected data, or required-reason API use. Audit the final app and any later dependencies against [Apple's required-reason API list](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api); declare applicable approved reasons based on actual usage. Confirm the manifest is included in the archive's app bundle. The manifest, public policy, and App Store privacy answers are separate deliverables.

### Capture screenshots

Capture the completed app with synthetic alarm labels and times, including the alarm list, editor, and clock. Show the real interface; do not imply features such as a system snooze button, non-English spoken audio, or continuously changing alarm speech.

Use Simulator's **File > Save Screen**, or capture the single booted simulator from Terminal:

```sh
mkdir -p build/store-screenshots
xcrun simctl io booted screenshot build/store-screenshots/alarms.png
```

If several simulators are booted, substitute the intended device's UDID from `xcrun simctl list devices booted` for `booted`. Capture the other screens with different filenames.

Provide iPhone and iPad screenshots because this target supports both. For example, Apple currently accepts a large iPhone portrait image at **1320 × 2868** and a 13-inch iPad portrait image at **2064 × 2752**. Choose simulator models whose native output matches the slots shown in App Store Connect, and consult the [current screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) before capturing. Do not stretch another device's image to fit. App preview videos are optional.

**Checkpoint:** final icon builds correctly, policy/support pages and in-app links work, screenshots exist for both device families, and device acceptance is recorded.

## 7. Create the App Store Connect app record

1. In the [developer account](https://developer.apple.com/account/), open **Certificates, Identifiers & Profiles > Identifiers**. Confirm Xcode has registered your identifier with the correct team. If it has not, use **+ > App IDs**, choose an explicit identifier, and enter exactly the bundle ID used in Xcode. Review and register it. See [Register an App ID](https://developer.apple.com/help/account/identifiers/register-an-app-id/).
2. In [App Store Connect](https://appstoreconnect.apple.com/), open **Apps > + > New App**. Select **iOS**, enter an available app name, choose the primary language, select that bundle ID, and assign an internal SKU such as `talking-clock-ios`. The SKU is your bookkeeping identifier, not a user-facing name.
3. Choose user access and create the record. This must exist before upload. If the bundle ID is missing, check the team/account and identifier registration; if creation is blocked, check agreements and your role. See [Apple's app-record instructions](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app).
4. Set the iOS version to match Xcode's Version field, such as `2.0`. Record the numeric Apple ID assigned to the app for your release notes and support records.

## 8. Fill in the store listing and compliance information

In your app's App Store Connect pages, save the following before submission. The current [platform-version field reference](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/) explains field limits and required metadata.

| Area | What to enter for this release |
| --- | --- |
| App Information | Available name, primary language, appropriate category such as Utilities, subtitle if desired, and truthful content-rights answers |
| Age rating | Complete the current questionnaire from the actual features; do not assume a rating because this is a clock |
| Version metadata | Description, relevant keywords, copyright owner/year, support URL, and optional marketing URL/promotional text |
| Screenshots | The final iPhone and iPad images, correctly assigned to device and language slots |
| App Privacy | Policy URL and answers reflecting the final binary and any integrated services |
| Pricing and Availability | Intended price, tax category where requested, and specific countries/regions |
| App Review Information | Monitored contact details, no sign-in requirement for this app, and reproducible alarm test steps |
| Version Release | **Manually release this version** for a first release you can control |

For this local-only implementation, **Data Not Collected** may be appropriate only after checking the final release against [Apple's privacy definitions](https://developer.apple.com/app-store/app-privacy-details/). Do not infer it solely from the empty manifest, especially if analytics, crash SDKs, or services were added. Enter and publish the answers through **App Privacy**, including the mandatory privacy-policy URL; see [Manage app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/).

Answer export-compliance questions for the actual binary. `ios/Configuration/Info.plist` currently sets `ITSAppUsesNonExemptEncryption` to `false`; the app uses Apple's SHA-256 implementation for audio filenames. Confirm that declaration still matches the shipped functionality and follow [Apple's encryption questionnaire](https://developer.apple.com/help/app-store-connect/manage-app-information/determine-and-upload-app-encryption-documentation). If App Store Connect shows Missing Compliance, complete the requested information before testing/submission rather than changing the flag merely to bypass it.

Complete trader-status declarations under **Business > Agreements > Compliance**. If distributing as a trader in the EU, Apple requires verification and public contact details. Assess your actual status; a free app does not automatically make you a non-trader. Follow [Apple's DSA instructions](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements), including the declaration even if you do not select EU distribution. Resolve other region-specific requirements shown for the storefronts you choose.

Review automatic availability on other platforms. Under **Pricing and Availability > iPhone and iPad Apps on Apple Silicon Mac**, opt out of **Make this app available** until that environment is validated. `SUPPORTS_MACCATALYST = NO` alone does not control this distribution option. See [Apple's availability instructions](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/manage-availability-of-iphone-and-ipad-apps-on-macs-with-apple-silicon). Review any Apple Vision Pro compatibility distribution option too; the native macOS app is a separate project request.

## 9. Archive, validate, and upload

1. Finish and review the release-preparation changes. Merge them through a PR after checks pass. On your Mac, update to that reviewed commit, retain only the intentional local signing-team setting, and record the commit plus any local signing configuration used for the archive.
2. Verify the target's Version and incremented Build, the paid signing team, and Release icon settings. In **Product > Scheme > Edit Scheme > Archive**, confirm **Release** (the shared scheme already uses it).
3. Select **Any iOS Device (arm64)** or an available physical-device destination. Do not select a simulator or My Mac. Choose **Product > Archive**.
4. When **Window > Organizer > Archives** opens, select the new TalkingClock archive. Verify app name, bundle ID, version, build, and team. Keep this `.xcarchive` and its debugging symbols; they are useful for diagnosing release crashes.
5. Choose **Validate App** if available and resolve its errors. Then choose **Distribute App > App Store Connect**, and upload using automatic signing. Review the certificate, provisioning profile, and entitlements. Xcode can create missing distribution signing assets with the appropriate account permissions. See [Apple's upload steps](https://help.apple.com/xcode/mac/current/en.lproj/dev442d7f2ca.html).
6. Use the distribution option that supports **TestFlight and App Store**. Do not choose **TestFlight Internal Only** for the release candidate: those builds cannot be submitted to the App Store. If Xcode manages build numbers automatically, record the final uploaded number. See [Apple's beta-release tutorial](https://developer.apple.com/tutorials/develop-in-swift/test-your-beta-app).
7. Wait for upload and App Store Connect processing, then find the exact version/build under **TestFlight**. Read any processing emails and resolve errors. An upload success message alone does not mean processing or App Review has passed.

**Checkpoint:** the intended build has processed successfully and is eligible for testing and App Store submission. Uploading it does not make it public.

## 10. Test the uploaded build with TestFlight

1. In App Store Connect's **TestFlight** tab, complete test information, a feedback email, and any compliance questions. Explain that testers should schedule an alarm several minutes ahead and check spoken delivery while locked.
2. Create an **Internal Testing** group, add yourself as an eligible App Store Connect user, and assign the processed build. Install Apple's TestFlight app on your iPhone/iPad, accept the invitation, and install Talking Clock from it.
3. Test the distributed build, disconnected from Xcode. Repeat locked/background/terminated delivery, restart/unlock, Stop/Open/snooze, weekly repeat, denied permissions, and the policy/support links. For a clean-install test, first remove synthetic alarms and preserve any data you need; deleting the app removes its local data. Also test upgrades over a prior beta if one exists.
4. Optionally create an **External Testing** group and invite people without App Store Connect access. Supply beta review information; the first external build needs TestFlight review. That approval is separate from public App Store review.
5. Review feedback/crashes, fix issues, increment Build, and upload again until the intended release build passes. Select that same tested build for submission. TestFlight builds expire after 90 days; see [Apple's TestFlight workflow](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/).

## 11. Submit for App Review

1. Confirm every release gate in [APP_STORE_CHECKLIST.md](../APP_STORE_CHECKLIST.md) has evidence. Select the matching processed/TestFlight-tested build in the App Store version's **Build** section.
2. Finish all required metadata, privacy, age-rating, pricing, availability, and compliance fields. Confirm **Manually release this version** and save.
3. Fill in reviewer contact details and explain the alarm flow. The following is a starting point; update it to match your tested build:

```text
Talking Clock requires iOS/iPadOS 26 or later and does not require an account.
Create an alarm a few minutes ahead, enable spoken time, and save.
Allow alarm access when prompted, then close the app and lock the device.
AlarmKit presents the system alarm using a chime and a prerecorded English
announcement of the scheduled time. The clip does not update while ringing.
Use Stop on the system alarm to dismiss it. To snooze, choose Open on the
system alarm, then tap Snooze in the app; repeating schedules are preserved.
Alarm and timer completion use AlarmKit. Clock and Timer interval speech currently requires the foreground; production background sessions remain gated on a recorded hour-long physical-device experiment. Before shipping background speech, update these notes with the validated continuous-audio behavior, user-start/stop controls, Live Activity, and force-quit limitation.
Privacy Policy and Support are available on the About sheet from the Clock screen's i button.
```

Use the final sentence only after adding and testing the policy link. Include a short demonstration attachment if it helps reproduce a device-only issue, but ensure reviewers can test the app directly.

4. Click **Add for Review**, open the resulting draft submission, then click **Submit for Review**. Adding to the draft alone does not submit the app. Follow [Apple's submission instructions](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app).
5. Monitor App Store Connect and email. If review requests changes, read the specific finding, reply with relevant reproduction details, and fix it. For code or bundled-asset changes, upload a new build and select it for resubmission; metadata-only corrections may not require a new binary. Do not assume review or approval will finish on a fixed schedule.

## 12. Publish and verify the public release

1. Once approved, a manual release waits in **Pending Developer Release**. Recheck price, regions, store text, support links, and that the selected build is the tested one.
2. Open that version, choose **Release This Version**, and confirm. Apple says availability can take up to 24 hours. See [release options and manual publication](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/select-an-app-store-version-release-option/).
3. Open the public App Store page in an intended storefront. Check the name, icon, screenshots, age rating, privacy label, price, and minimum OS. Install the public app on a test device, then run the basic locked-device alarm and snooze checks again.
4. Save the public URL, App Store version/build, source commit, Xcode version, archive location, and device-test record. Update the release checklist based on actual results.
5. If you use a GitHub release/tag, associate it with the shipped source commit and include the App Store build number. A `v*` tag only triggers the repository's test/build CI; it does not sign, upload, submit, or publish the app.
6. Monitor support, crashes, and reviews. For the next release, increase the public version as appropriate, use a fresh build number, test it, and repeat the upload/review/release steps. Keep membership, agreements, support pages, and toolchain requirements current.

## Troubleshooting

| Symptom | First checks |
| --- | --- |
| `xcodebuild` requires Xcode / wrong SDK | Re-select the full Xcode app with `xcode-select`; run `xcodebuild -showsdks` |
| Device not available or OS unsupported | Unlock, trust/pair, enable Developer Mode, and use Xcode supporting that device OS |
| Bundle identifier unavailable | Confirm your paid team owns it; choose another before creating/uploading the permanent app record |
| Signing/profile/certificate error | Confirm team, automatic signing in Release, active membership, agreements, account permissions, and network access; use Xcode's signing diagnostics |
| Archive disabled or wrong product archived | Select the root TalkingClock scheme and a generic iOS device, not a simulator or `v0` project |
| Missing icon / invalid App Store icon | Check target membership, Release `AppIcon` setting, required wells, and image dimensions/transparency |
| Duplicate build or build not selectable | Increase Build and upload again; check version/identifier match, processing errors, compliance, and whether it was Internal Only |
| Privacy declaration warning | Audit actual APIs and bundled manifest; fix the relevant declaration and upload a new build |
| Preview speaks but scheduled alarm does not | Check authorization, system alarm volume, device state, generated audio, and device logs; do not ship until system delivery is verified |
| Approved but not public | Check manual-release status, Release This Version, selected territories, and propagation time |

Keep error reports free of signing credentials and personal alarm labels. [QUICKSTART.md](../QUICKSTART.md) describes storage and recovery behavior when a scheduled change fails.
