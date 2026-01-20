# App Store Submission Checklist

Use this checklist to ensure you've completed all steps before submitting to the App Store.

## Pre-Submission Checklist

### 1. Apple Developer Account
- [ ] Paid Apple Developer membership active ($99/year)
- [ ] Account in good standing
- [ ] Can access App Store Connect

### 2. App Assets Ready

#### App Icon
- [ ] 1024x1024 PNG app icon created (no transparency, no rounded corners)
- [ ] App icon added to Assets.xcassets/AppIcon.appiconset/
- [ ] Icon follows App Store guidelines (no text that's too small)

#### Screenshots
- [ ] 6.7" iPhone screenshots (iPhone 15 Pro Max) - REQUIRED
- [ ] 5.5" iPhone screenshots (iPhone 8 Plus) - REQUIRED
- [ ] 12.9" iPad screenshots (if supporting iPad) - OPTIONAL
- [ ] At least 3 screenshots per device size
- [ ] Screenshots show key features clearly

#### App Preview Video (Optional)
- [ ] 15-30 second video showing app in action
- [ ] Exported in correct format and size
- [ ] Shows actual app interface (no marketing graphics)

### 3. App Configuration in Xcode

#### General Tab
- [ ] Display Name: "Talking Clock"
- [ ] Bundle Identifier: Unique (e.g., com.yourcompany.talkingclock)
- [ ] Version: 1.0
- [ ] Build: 1
- [ ] Deployment Target: iOS 16.0
- [ ] Team selected for signing

#### Signing & Capabilities
- [ ] Automatically manage signing: ENABLED
- [ ] Team selected
- [ ] Provisioning profile valid
- [ ] Background Modes capability added with "Audio" enabled

#### Info.plist
- [ ] UIBackgroundModes includes "audio"
- [ ] NSUserNotificationUsageDescription present
- [ ] NSSpeechRecognitionUsageDescription present (or removed if not needed)

### 4. Testing Complete

#### Simulator Testing
- [ ] App launches successfully
- [ ] Clock updates every second
- [ ] Interval picker works
- [ ] Toggles work
- [ ] "Speak Time" button works
- [ ] Settings persist after app restart
- [ ] No crashes or freezes
- [ ] Dark mode works correctly

#### Real Device Testing
- [ ] Tested on actual iPhone/iPad
- [ ] Background announcements work
- [ ] Notifications appear correctly
- [ ] Audio works when device is locked
- [ ] No memory leaks or performance issues
- [ ] Battery usage is acceptable
- [ ] Works on iOS 16.0+ devices

### 5. App Store Connect Metadata

#### Basic Information
- [ ] App Name: Max 30 characters
- [ ] Subtitle: Max 30 characters (optional but recommended)
- [ ] Primary Language: English (U.S.)
- [ ] Category: Utilities or Productivity
- [ ] SKU: Unique identifier created

#### Description & Keywords
- [ ] Description written (up to 4000 characters)
- [ ] Description highlights key features
- [ ] Keywords added (max 100 characters, comma-separated)
- [ ] Promotional text (optional, 170 characters)

#### URLs
- [ ] Support URL: Valid and accessible
- [ ] Privacy Policy URL: Valid and accessible (REQUIRED)
- [ ] Marketing URL: Valid (optional)

#### Pricing & Availability
- [ ] Price tier selected (Free or paid)
- [ ] Available territories selected
- [ ] Release timing chosen (automatic or manual)

#### Age Rating
- [ ] Questionnaire completed
- [ ] Rating is appropriate (likely 4+)

#### App Privacy
- [ ] Privacy questions answered
- [ ] Data collection types specified (likely "No data collected")
- [ ] Privacy details submitted

### 6. Build & Archive

#### Pre-Archive
- [ ] All code changes committed to git
- [ ] Version and build numbers updated
- [ ] Device target set to "Any iOS Device (arm64)"
- [ ] Build configuration set to "Release"
- [ ] Clean build folder (Cmd + Shift + K)

#### Archive
- [ ] Archive created successfully (Product > Archive)
- [ ] Archive appears in Organizer
- [ ] Archive validated successfully (no errors)

#### Upload
- [ ] Archive uploaded to App Store Connect
- [ ] Upload completed without errors
- [ ] Build appears in App Store Connect (wait 10-30 min)
- [ ] Build processing completed successfully

### 7. Final App Store Connect Setup

#### Version Information
- [ ] Build selected for this version
- [ ] Screenshots uploaded for all required sizes
- [ ] App icon displays correctly in preview

#### App Review Information
- [ ] Contact info (name, phone, email) provided
- [ ] Review notes added (how to test the app)
- [ ] Demo account info (if required) - N/A for this app
- [ ] Sign-in required: NO

#### Export Compliance
- [ ] Export compliance questions answered
- [ ] Encryption usage declared correctly

### 8. Submission

- [ ] All required fields have green checkmarks
- [ ] "Submit for Review" button is active
- [ ] Export compliance declared
- [ ] App submitted successfully
- [ ] Received confirmation email

### 9. Post-Submission

- [ ] Check App Store Connect for status updates
- [ ] Monitor email for review updates
- [ ] Respond to any feedback from Apple within 48 hours
- [ ] Keep build archived locally for reference

## Common Issues to Check Before Submitting

### App Review Rejections to Avoid

- [ ] Privacy Policy is accessible and covers your app
- [ ] App doesn't crash on launch
- [ ] All features described in screenshots work
- [ ] Permissions are explained clearly to users
- [ ] No placeholder text or "Lorem ipsum"
- [ ] No broken links in app or metadata
- [ ] App works without requiring sign-in
- [ ] App provides value beyond just being a website wrapper
- [ ] UI is polished and functional
- [ ] App follows iOS Human Interface Guidelines

### Technical Issues to Verify

- [ ] No hardcoded test credentials
- [ ] No debug print statements that expose sensitive info
- [ ] App handles edge cases (no internet, low battery, etc.)
- [ ] All supported languages display correctly
- [ ] App doesn't request unnecessary permissions
- [ ] Memory usage is reasonable
- [ ] App bundle size is optimized

## Timeline Expectations

- [ ] Understand review typically takes 24-48 hours
- [ ] Have plan for addressing rejection if it occurs
- [ ] Know that first submission may take longer
- [ ] Prepared to respond to Apple feedback quickly

## Post-Approval Actions

- [ ] Plan for monitoring user reviews
- [ ] Set up App Analytics tracking
- [ ] Prepare marketing materials
- [ ] Plan social media announcements
- [ ] Consider app updates roadmap
- [ ] Set up support email/system for user questions

## Emergency Checklist (If Rejected)

1. [ ] Read rejection reason carefully
2. [ ] Check Apple's Resolution Center for details
3. [ ] Fix identified issues
4. [ ] Increment build number (keep version same)
5. [ ] Re-test thoroughly
6. [ ] Upload new build
7. [ ] Reply to Apple's message with explanation of fixes
8. [ ] Resubmit for review

---

## Quick Reference Links

- **App Store Connect**: https://appstoreconnect.apple.com/
- **Apple Developer**: https://developer.apple.com/
- **Human Interface Guidelines**: https://developer.apple.com/design/human-interface-guidelines/
- **App Store Review Guidelines**: https://developer.apple.com/app-store/review/guidelines/
- **App Analytics**: https://appstoreconnect.apple.com/analytics

---

**Last Updated**: January 20, 2026

Print this checklist and check off items as you complete them!
