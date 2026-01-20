# Talking Clock iOS App

A clean, minimalistic iOS app that displays the time and announces it at configurable intervals using system text-to-speech.

## Features

- **Digital Clock Display**: Large, easy-to-read time in HH:mm:ss format with date
- **Analog Clock**: Optional canvas-drawn analog clock with hour markers and hands
- **Configurable Intervals**: Announce time every 10/20/30 seconds or 1/2/5/10/15/30 minutes
- **Text-to-Speech**: System voice announces the current time
- **Background Announcements**: Continue announcements when app is in background
- **Settings Persistence**: All preferences saved using UserDefaults
- **Manual Trigger**: Button to speak time on demand
- **Dark Mode Support**: Automatic adaptation to system appearance

## Requirements

- iOS 16.0+
- Xcode 15.0+
- macOS for development

## Project Structure

```
TalkingClock/
├── TalkingClock.xcodeproj/          # Xcode project file
└── TalkingClock/                     # Source code
    ├── App/
    │   └── TalkingClockApp.swift     # App entry point
    ├── Models/
    │   ├── TimeUnit.swift            # Seconds/minutes enum
    │   └── ClockSettings.swift       # Settings with persistence
    ├── ViewModels/
    │   └── ClockViewModel.swift      # Timer and state management
    ├── Services/
    │   ├── SpeechService.swift       # AVSpeechSynthesizer wrapper
    │   └── NotificationService.swift # Local notifications
    ├── Views/
    │   ├── ContentView.swift         # Main layout
    │   ├── DigitalClockView.swift    # Time display
    │   ├── AnalogClockView.swift     # Canvas-drawn clock
    │   ├── IntervalPickerView.swift  # Interval configuration
    │   └── SettingsToggleView.swift  # Settings toggles
    ├── Resources/
    │   └── Assets.xcassets/          # App icon and colors
    └── Info.plist                    # App configuration
```

## Architecture

- **Framework**: SwiftUI
- **Pattern**: MVVM (Model-View-ViewModel)
- **Dependencies**: None - uses only system frameworks
- **Target**: iOS 16+

## Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url>
cd ios-talking-clock
```

### 2. Open in Xcode

```bash
open TalkingClock/TalkingClock.xcodeproj
```

Or double-click `TalkingClock.xcodeproj` in Finder.

## Testing on Simulator

### Quick Start

1. **Open Xcode** and load the project
2. **Select a Simulator** from the device menu (top-left):
   - Click the device selector next to the scheme
   - Choose any iPhone simulator (e.g., "iPhone 15 Pro")
3. **Build and Run**:
   - Press `Cmd + R` or click the Play button
   - Wait for the simulator to launch and install the app

### Testing Features

1. **Time Display**: Verify the clock updates every second
2. **Interval Picker**:
   - Change between seconds and minutes
   - Select different interval values
   - Verify settings persist after restarting the app
3. **Analog Clock Toggle**: Toggle on/off to see the animated transition
4. **Manual Speak**: Tap "Speak Time" button to hear the announcement
5. **Auto-Announcements**:
   - Enable "Auto-Announce Time"
   - Set interval to 10 seconds
   - Wait for automatic announcement
6. **Background Mode**:
   - Run the app
   - Press `Cmd + Shift + H` to go to home screen
   - Wait for scheduled announcement (notifications will appear)
7. **Dark Mode**:
   - In simulator, go to Settings > Developer > Dark Appearance
   - Verify UI adapts correctly

### Simulator Limitations

- **No background audio**: Simulator may not play audio when app is in background
- **Speech synthesis**: May sound different from real device
- **Notifications**: Work but may have different timing behavior

## Testing on Physical Device

### Prerequisites

1. **Apple Developer Account**: Free or paid account
2. **USB Cable**: To connect device to Mac
3. **Trust Configuration**: Device must trust your Mac

### Setup Steps

#### 1. Connect Your Device

1. Connect iPhone/iPad to your Mac via USB
2. Unlock the device
3. If prompted, tap "Trust This Computer" on the device
4. Enter device passcode

#### 2. Configure Signing in Xcode

1. Open the project in Xcode
2. Select the project in the navigator (blue icon at top)
3. Select the "TalkingClock" target
4. Go to "Signing & Capabilities" tab
5. Configure Team:
   - **Free Account**:
     - Team: Select your personal team (Your Name)
     - Bundle Identifier: Change to unique ID (e.g., `com.yourname.talkingclock`)
   - **Paid Account**:
     - Team: Select your development team
     - Leave Bundle Identifier as is or customize

6. Ensure "Automatically manage signing" is checked
7. Wait for Xcode to provision the app

#### 3. Build and Run

1. Select your device from the device menu
2. Press `Cmd + R` to build and install
3. First time only: On device, go to Settings > General > VPN & Device Management
4. Tap your developer account and tap "Trust"
5. Return to the app and launch it

#### 4. Grant Permissions

When the app launches:
1. Tap "Allow" when prompted for notifications
2. Test the "Speak Time" button to verify audio works

### Testing on Device

Test all simulator features plus:
1. **Background Audio**:
   - Enable auto-announce with 1-minute interval
   - Lock the device or switch to another app
   - Verify announcements continue (audio plays even when locked)
2. **Notifications**:
   - Put app in background
   - Wait for notification to appear
   - Tap notification to open app
3. **Real Speech Quality**: Verify voice quality is clear
4. **Battery Impact**: Monitor battery usage in Settings > Battery

## Building for App Store

### Prerequisites

1. **Paid Apple Developer Account** ($99/year)
   - Enroll at: https://developer.apple.com/programs/
   - Wait for approval (can take 24-48 hours)

2. **App Store Connect Access**
   - Access: https://appstoreconnect.apple.com/
   - Sign in with your Apple Developer account

### Step 1: Prepare App Assets

#### App Icon

Create app icon in required sizes using a tool like:
- [AppIconMaker.co](https://appiconmaker.co/)
- [MakeAppIcon.com](https://makeappicon.com/)
- Figma/Sketch/Photoshop with export plugin

Required sizes:
- 1024x1024 (App Store)
- 60x60, 76x76, 83.5x83.5, etc. (various devices)

Add to `TalkingClock/Resources/Assets.xcassets/AppIcon.appiconset/`

#### Screenshots

Capture screenshots on required device sizes:
- 6.7" iPhone (iPhone 15 Pro Max) - Required
- 5.5" iPhone (iPhone 8 Plus) - Required
- 12.9" iPad Pro - If supporting iPad
- 6.5" iPhone for older iOS versions

To capture in Xcode:
1. Run on simulator of required size
2. `Cmd + S` to save screenshot
3. Screenshots save to Desktop

#### App Store Metadata

Prepare the following:
- **App Name**: "Talking Clock" or your chosen name (max 30 chars)
- **Subtitle**: Brief description (max 30 chars)
  - Example: "Voice time announcements"
- **Description**: Full description (max 4000 chars)
  - See template below
- **Keywords**: Comma-separated (max 100 chars)
  - Example: "clock,time,speak,voice,announce,accessibility"
- **Support URL**: Your website or GitHub repo
- **Privacy Policy URL**: Required - see template below

### Step 2: Configure App in Xcode

#### Update Bundle Identifier

1. In Xcode, select project > TalkingClock target
2. General tab:
   - **Display Name**: Talking Clock
   - **Bundle Identifier**: com.yourcompany.talkingclock
   - **Version**: 1.0
   - **Build**: 1

#### Configure App Category

1. General tab > Deployment Info
2. Set **Deployment Target**: iOS 16.0

#### Review Info.plist

Ensure these keys exist in `Info.plist`:
- `UIBackgroundModes` with `audio`
- `NSUserNotificationUsageDescription`: "We need notification permission to announce the time when the app is in the background."
- `NSSpeechRecognitionUsageDescription`: "This app uses text-to-speech to announce the time."

#### Add Privacy Manifest (iOS 17+)

Create `PrivacyInfo.xcprivacy` if needed for tracking/data collection (likely not needed for this app).

### Step 3: Create App in App Store Connect

1. **Log in** to [App Store Connect](https://appstoreconnect.apple.com/)

2. **Create New App**:
   - Click "My Apps" > "+" > "New App"
   - Platform: iOS
   - Name: Talking Clock
   - Primary Language: English (U.S.)
   - Bundle ID: Select the one you configured in Xcode
   - SKU: Any unique identifier (e.g., TALKING-CLOCK-001)
   - User Access: Full Access

3. **App Information**:
   - Category: Utilities or Productivity
   - Secondary Category (optional): Lifestyle
   - Age Rating: Click "Edit" and answer questions (likely 4+)

4. **Pricing and Availability**:
   - Price: Free or set your price
   - Availability: All territories or select specific countries

### Step 4: Archive the App

#### 1. Select "Any iOS Device (arm64)"

In Xcode, select scheme target as "Any iOS Device (arm64)" from device menu.

#### 2. Clean Build Folder

```
Product > Clean Build Folder (Cmd + Shift + K)
```

#### 3. Archive

```
Product > Archive (Cmd + Option + Shift + R)
```

Wait for archive to complete (may take 2-5 minutes).

#### 4. Organizer Opens

Archives window opens automatically showing your archive.

If not visible:
```
Window > Organizer (Cmd + Option + Shift + O)
```

### Step 5: Upload to App Store Connect

1. **Validate App**:
   - In Organizer, select your archive
   - Click "Validate App"
   - Select your team
   - Choose automatic signing
   - Click "Validate"
   - Wait for validation (2-5 minutes)
   - Fix any errors if they appear

2. **Distribute App**:
   - Click "Distribute App"
   - Select "App Store Connect"
   - Click "Next"
   - Choose "Upload"
   - Select automatic signing
   - Click "Upload"
   - Wait for upload to complete (5-10 minutes)

3. **Confirmation**:
   - You'll receive email when processing completes
   - Build appears in App Store Connect within 10-30 minutes

### Step 6: Complete App Store Listing

1. **Return to App Store Connect** > Your App

2. **App Store Tab**:

   **App Previews and Screenshots**:
   - Add screenshots for 6.7" iPhone
   - Add screenshots for 5.5" iPhone
   - Optional: Add app preview videos

   **Promotional Text** (optional):
   - Never miss the time with voice announcements

   **Description**:
   ```
   Talking Clock is a simple, elegant time-telling app that announces the current time at your chosen intervals.

   FEATURES:
   • Beautiful digital and analog clock displays
   • Customizable announcement intervals (every 10, 20, 30 seconds or 1, 2, 5, 10, 15, 30 minutes)
   • Clear, natural voice announcements
   • Works in background - continue hearing time even when using other apps
   • Manual "Speak Time" button for on-demand announcements
   • Toggle analog clock on/off
   • Dark mode support
   • Settings automatically saved

   PERFECT FOR:
   • Time awareness during work or study
   • Accessibility - helpful for visually impaired users
   • Workouts and timed activities
   • Meditation and focus sessions
   • Anyone who wants time awareness without checking their phone

   PRIVACY:
   • No data collection
   • No ads
   • No accounts required
   • Works completely offline

   Simply set your preferred announcement interval, enable auto-announce, and let the app keep you informed of the time throughout your day.
   ```

   **Keywords**:
   ```
   clock,time,speak,voice,announce,talking,accessibility,timer,hourly,alarm
   ```

   **Support URL**:
   - Your website or GitHub repo URL

   **Marketing URL** (optional):
   - Same as support URL or dedicated landing page

3. **App Privacy**:
   - Click "Edit" next to App Privacy
   - Answer: "No, we do not collect data from this app"
   - Click "Save"

4. **Build**:
   - Scroll to "Build" section
   - Click "+" to select build
   - Choose the build you uploaded
   - Click "Done"

5. **Age Rating**:
   - Verify age rating is correct (should be 4+)

6. **App Review Information**:
   - First Name, Last Name, Phone, Email
   - Notes (optional):
     ```
     This app announces the time at configurable intervals using text-to-speech.
     To test:
     1. Tap "Speak Time" button to hear immediate announcement
     2. Set interval to "10 seconds" and enable "Auto-Announce Time"
     3. Wait 10 seconds for automatic announcement
     4. Background announcements work via notifications and audio session
     ```
   - Sign-in required: No
   - Demo account: Not needed

7. **Version Release**:
   - Automatically release this version
   OR
   - Manually release this version (you control when it goes live)

8. **Save** all changes

### Step 7: Submit for Review

1. Click "Add for Review" (top right)
2. Answer export compliance questions:
   - "Does your app use encryption?" → No (or Yes if you add HTTPS in future)
   - If Yes: "Is your app exempt from encryption requirements?" → Yes
3. Click "Submit to App Review"

### Step 8: App Review Process

**Timeline**:
- Initial review: 24-48 hours typically
- If rejected: Fix issues and resubmit

**Common Rejection Reasons & Fixes**:

1. **Missing Privacy Policy**:
   - Solution: Create simple privacy policy and host online
   - Template:
     ```
     Privacy Policy for Talking Clock

     This app does not collect, store, or share any personal data.
     All settings are stored locally on your device only.
     No analytics or tracking is performed.

     Contact: your.email@example.com
     ```

2. **Insufficient App Description**:
   - Solution: Expand description with clear feature list and use cases

3. **Crash on Launch**:
   - Solution: Test thoroughly on real device before submitting

4. **Missing Functionality**:
   - Solution: Ensure all features work in submitted build

**Status Tracking**:
- Check status in App Store Connect > My Apps > Your App
- Statuses: Waiting for Review → In Review → Pending Developer Release / Ready for Sale

### Step 9: Release

**Automatic Release**:
- App goes live automatically when approved

**Manual Release**:
- After approval, status shows "Pending Developer Release"
- Click "Release This Version" when ready

### Step 10: Post-Release

1. **Monitor Reviews**: Respond to user feedback
2. **Track Downloads**: Check App Analytics in App Store Connect
3. **Update App**:
   - Increment version number (1.0 → 1.1)
   - Increment build number (1 → 2)
   - Repeat archive and upload process
4. **Promote**: Share on social media, website, etc.

## App Store Listing Templates

### Privacy Policy (Simple)

Host this at a URL (GitHub Pages, your website, etc.):

```markdown
# Privacy Policy for Talking Clock

Last updated: January 20, 2026

## Data Collection
Talking Clock does not collect, store, transmit, or share any personal data.

## Local Storage
All app settings are stored locally on your device using iOS UserDefaults.
This data never leaves your device.

## Permissions
The app requests the following permissions:
- **Notifications**: To announce the time when the app is in background
- **Audio**: To play speech announcements

These permissions are used solely for app functionality and no data is collected.

## Third-Party Services
This app does not use any third-party analytics, tracking, or advertising services.

## Children's Privacy
This app does not knowingly collect any information from children.

## Changes to Privacy Policy
We may update this policy occasionally. Changes will be posted at this URL.

## Contact
For questions about this privacy policy, contact: your.email@example.com
```

### Support Page (Simple)

```markdown
# Talking Clock - Support

## How to Use
1. The app displays the current time with digital and optional analog clock
2. Set your announcement interval using the dropdown menus
3. Enable "Auto-Announce Time" to hear automatic announcements
4. Tap "Speak Time" button to hear time immediately
5. Toggle "Show Analog Clock" to show/hide the analog clock face

## Troubleshooting

### No voice announcements
- Ensure device volume is up
- Check that device is not in silent mode
- Grant notification permission when prompted

### Announcements stop in background
- Ensure notifications are allowed in iOS Settings > Talking Clock
- Check that Low Power Mode is not active

### Settings not saving
- Close and reopen the app
- Restart your device

## Feature Requests
Submit feature requests at: [GitHub URL or email]

## Bug Reports
Report bugs at: [GitHub URL or email]

## Contact
Email: your.email@example.com
```

## Versioning Strategy

- **1.0**: Initial release
- **1.1**: Minor features, bug fixes
- **2.0**: Major features, UI overhaul

## License

[Your chosen license - MIT, Apache 2.0, etc.]

## Author

[Your name/organization]

## Acknowledgments

Built with SwiftUI and AVFoundation.
