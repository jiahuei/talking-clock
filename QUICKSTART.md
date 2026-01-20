# Quick Start Guide

Get the Talking Clock app running in under 5 minutes.

## For Testing on Simulator

### Step 1: Open Project
```bash
cd ios-talking-clock
open TalkingClock/TalkingClock.xcodeproj
```

### Step 2: Select Simulator
- Click device selector (top-left, next to scheme name)
- Choose any iPhone simulator (e.g., "iPhone 15 Pro")

### Step 3: Run
- Press `Cmd + R` or click the Play ▶️ button
- Wait for simulator to launch (30-60 seconds)

### Step 4: Test
1. Tap "Speak Time" to hear announcement
2. Change interval to "10 seconds"
3. Enable "Auto-Announce Time"
4. Wait 10 seconds for automatic announcement

**Done!** The app is running in the simulator.

---

## For Testing on Your iPhone

### Step 1: Connect Device
- Plug iPhone into Mac with USB cable
- Unlock iPhone
- Tap "Trust This Computer" on iPhone
- Enter iPhone passcode

### Step 2: Open Project
```bash
cd ios-talking-clock
open TalkingClock/TalkingClock.xcodeproj
```

### Step 3: Configure Signing
1. Click project name in navigator (blue icon)
2. Select "TalkingClock" target
3. Go to "Signing & Capabilities" tab
4. Under "Team", select your Apple ID
5. Change "Bundle Identifier" to something unique:
   - Example: `com.yourname.talkingclock`
   - Replace `yourname` with your actual name

### Step 4: Select Your Device
- Click device selector (top-left)
- Choose your iPhone from the list

### Step 5: Build & Run
- Press `Cmd + R`
- Wait for build to complete (1-2 minutes first time)
- **If error "Untrusted Developer"**:
  - On iPhone: Settings > General > VPN & Device Management
  - Tap your developer account
  - Tap "Trust [Your Name]"
  - Return to app and launch

### Step 6: Test
1. Tap "Allow" when asked for notification permission
2. Tap "Speak Time" button
3. Hear the time announcement

**Done!** The app is running on your iPhone.

---

## For App Store Submission

See the full [App Store Checklist](APP_STORE_CHECKLIST.md) and detailed guide in [README.md](README.md#building-for-app-store).

### Prerequisites
- Paid Apple Developer Account ($99/year)
- App icon designed (1024x1024)
- Screenshots captured
- Privacy policy written and hosted

### Quick Steps
1. Prepare assets (icon, screenshots)
2. Update bundle ID and version in Xcode
3. Create app in App Store Connect
4. Archive: Product > Archive (`Cmd + Option + Shift + R`)
5. Validate and upload archive
6. Complete metadata in App Store Connect
7. Submit for review

**Timeline**: Expect 24-48 hours for initial review.

---

## Troubleshooting

### "Failed to build"
- Check that you've selected an iOS simulator or device (not "My Mac")
- Try: Product > Clean Build Folder (`Cmd + Shift + K`)
- Restart Xcode

### "Signing for 'TalkingClock' requires a development team"
- Go to Signing & Capabilities tab
- Select a team under "Team" dropdown
- If no team: Add Apple ID in Xcode Preferences > Accounts

### "Unable to install"
- On device, delete any previous version of the app
- Trust your developer account in device Settings
- Try cleaning and rebuilding

### No sound in simulator
- Check Mac volume
- Try on real device instead (simulators have audio limitations)

### App crashes on launch
- Check Console in Xcode (⌘ + Shift + C) for error messages
- Verify all files are included in target
- Clean build folder and rebuild

---

## Project Structure Overview

```
TalkingClock/
├── TalkingClock.xcodeproj       # Open this file
└── TalkingClock/
    ├── App/                      # Entry point
    ├── Models/                   # Data structures
    ├── ViewModels/               # Business logic
    ├── Services/                 # Speech & notifications
    ├── Views/                    # UI components
    └── Resources/                # Assets & icons
```

---

## Next Steps

- **Read full documentation**: [README.md](README.md)
- **Check App Store guide**: [README.md#building-for-app-store](README.md#building-for-app-store)
- **Review checklist**: [APP_STORE_CHECKLIST.md](APP_STORE_CHECKLIST.md)
- **Privacy policy**: [PRIVACY.md](PRIVACY.md)
- **Support page**: [SUPPORT.md](SUPPORT.md)

---

## Common Commands

| Action | Shortcut | Menu |
|--------|----------|------|
| Build & Run | `Cmd + R` | Product > Run |
| Stop | `Cmd + .` | Product > Stop |
| Clean | `Cmd + Shift + K` | Product > Clean Build Folder |
| Archive | `Cmd + Option + Shift + R` | Product > Archive |
| Organizer | `Cmd + Option + Shift + O` | Window > Organizer |

---

## Getting Help

- **Documentation**: See [README.md](README.md)
- **Issues**: Check existing issues or create new one
- **Support**: [your-email@example.com]

---

**Happy Coding!** 🚀
