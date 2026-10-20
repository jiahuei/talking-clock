# Talking Clock - Alarm Feature Implementation Plan

## Overview

Add a tabbed interface with an Alarms tab featuring loud alarms that announce the current time. Implement a freemium model with 2 free alarms and up to 10 alarms for PRO users.

## Requirements

### Core Features
1. **Tabbed Navigation**: Clock tab (existing) + Alarms tab (new)
2. **Loud Alarms**: Maximum volume audio playback with escalating sound
3. **Time Announcement**: Speak current time when alarm fires
4. **Freemium Model**: 2 free alarms, up to 10 with PRO upgrade

### Alarm Capabilities
- Add/edit/delete alarms
- Enable/disable individual alarms
- Set alarm time (hour:minute)
- Repeat options (once, daily, weekdays, weekends, custom days)
- Snooze functionality (5 min default)
- Label/name for each alarm

## Architecture

### New Files to Create

```
TalkingClock/
├── Models/
│   ├── Alarm.swift                    # Alarm data model
│   ├── RepeatOption.swift             # Repeat days enum
│   └── PurchaseManager.swift          # In-app purchase handling
├── ViewModels/
│   ├── AlarmViewModel.swift           # Alarm list management
│   └── AlarmEditorViewModel.swift     # Single alarm editing
├── Services/
│   ├── AlarmScheduler.swift           # Local notification scheduling
│   ├── AlarmSoundPlayer.swift         # Loud audio playback
│   └── StoreKitManager.swift          # StoreKit 2 integration
├── Views/
│   ├── MainTabView.swift              # Tab container
│   ├── AlarmListView.swift            # Alarm list screen
│   ├── AlarmRowView.swift             # Single alarm row
│   ├── AlarmEditorView.swift          # Add/edit alarm sheet
│   ├── AlarmFiringView.swift          # Full-screen alarm UI
│   ├── UpgradeProView.swift           # PRO upgrade prompt
│   └── ProBadgeView.swift             # PRO badge component
└── Resources/
    └── Sounds/
        └── loud_alarm.caf             # Custom loud alarm sound
```

### Files to Modify

```
TalkingClock/
├── App/
│   └── TalkingClockApp.swift          # Add alarm firing detection
├── Views/
│   └── ContentView.swift              # Wrap in MainTabView
└── Info.plist                         # Add notification categories
```

## Data Models

### 1. Alarm Model

```swift
// Models/Alarm.swift
import Foundation

struct Alarm: Identifiable, Codable, Equatable {
    let id: UUID
    var time: DateComponents          // hour, minute only
    var isEnabled: Bool
    var label: String
    var repeatDays: Set<Weekday>      // empty = one-time alarm
    var snoozeEnabled: Bool
    var soundName: String             // for future custom sounds

    var nextFireDate: Date? { ... }   // Computed: next scheduled time
    var repeatDescription: String { ... } // "Daily", "Weekdays", etc.

    static let `default` = Alarm(
        id: UUID(),
        time: DateComponents(hour: 8, minute: 0),
        isEnabled: true,
        label: "Alarm",
        repeatDays: [],
        snoozeEnabled: true,
        soundName: "loud_alarm"
    )
}
```

### 2. Weekday Enum

```swift
// Models/RepeatOption.swift
import Foundation

enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }
    var shortName: String { ... }     // "Sun", "Mon", etc.
    var fullName: String { ... }      // "Sunday", "Monday", etc.

    static var weekdays: Set<Weekday> { [.monday, .tuesday, .wednesday, .thursday, .friday] }
    static var weekends: Set<Weekday> { [.saturday, .sunday] }
}
```

### 3. Pro Status Model

```swift
// Models/PurchaseManager.swift
import Foundation

class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    @Published private(set) var isPro: Bool = false

    let freeAlarmLimit = 2
    let proAlarmLimit = 10

    var currentLimit: Int { isPro ? proAlarmLimit : freeAlarmLimit }

    func canAddAlarm(currentCount: Int) -> Bool
    func loadPurchaseStatus()
    func restorePurchases() async
}
```

## Services

### 1. Alarm Scheduler

```swift
// Services/AlarmScheduler.swift
import UserNotifications

class AlarmScheduler {
    static let shared = AlarmScheduler()

    private let notificationCenter = UNUserNotificationCenter.current()

    // Schedule alarm notifications
    func scheduleAlarm(_ alarm: Alarm)
    func cancelAlarm(_ alarm: Alarm)
    func rescheduleAllAlarms(_ alarms: [Alarm])

    // Handle snooze
    func snoozeAlarm(_ alarm: Alarm, minutes: Int = 5)

    // Notification categories for actions
    func registerNotificationCategories()
}
```

**Notification Setup:**
- Category: `ALARM_CATEGORY`
- Actions: "Snooze" (5 min), "Stop"
- Critical alerts for maximum volume (requires entitlement)
- Time-sensitive notifications (iOS 15+)

### 2. Alarm Sound Player

```swift
// Services/AlarmSoundPlayer.swift
import AVFoundation
import MediaPlayer

class AlarmSoundPlayer: ObservableObject {
    static let shared = AlarmSoundPlayer()

    private var audioPlayer: AVAudioPlayer?
    private var speechService = SpeechService.shared
    private var originalVolume: Float = 0

    @Published var isPlaying: Bool = false

    // Maximum volume alarm playback
    func startAlarm(soundName: String)
    func stopAlarm()
    func speakTime()

    // Audio session for alarm (ignores silent mode)
    private func configureAudioSession()

    // Volume control
    private func setMaxVolume()
    private func restoreVolume()
}
```

**Loud Alarm Strategy:**
1. Set audio session category to `.playback` with options `.duckOthers`
2. Override silent mode using `.mixWithOthers` removal
3. Set system volume to maximum programmatically (using MPVolumeView)
4. Play looping alarm sound
5. After 2-3 loops, announce time via speech
6. Continue looping until dismissed
7. Restore original volume on stop

### 3. StoreKit Manager

```swift
// Services/StoreKitManager.swift
import StoreKit

class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading: Bool = false

    static let proProductID = "com.yourcompany.talkingclock.pro"

    var isPro: Bool { purchasedProductIDs.contains(Self.proProductID) }

    // StoreKit 2 methods
    func loadProducts() async
    func purchase(_ product: Product) async throws -> Transaction?
    func restorePurchases() async
    func checkEntitlements() async

    // Transaction listener
    func listenForTransactions() -> Task<Void, Error>
}
```

## View Models

### 1. Alarm View Model

```swift
// ViewModels/AlarmViewModel.swift
import Foundation
import Combine

class AlarmViewModel: ObservableObject {
    @Published var alarms: [Alarm] = []
    @Published var showingEditor: Bool = false
    @Published var showingUpgrade: Bool = false
    @Published var editingAlarm: Alarm?
    @Published var firingAlarm: Alarm?

    private let scheduler = AlarmScheduler.shared
    private let purchaseManager = PurchaseManager.shared

    var canAddAlarm: Bool {
        purchaseManager.canAddAlarm(currentCount: alarms.count)
    }

    // CRUD operations
    func addAlarm(_ alarm: Alarm)
    func updateAlarm(_ alarm: Alarm)
    func deleteAlarm(_ alarm: Alarm)
    func toggleAlarm(_ alarm: Alarm)

    // Add button action
    func addButtonTapped() {
        if canAddAlarm {
            editingAlarm = nil
            showingEditor = true
        } else {
            showingUpgrade = true
        }
    }

    // Persistence
    func loadAlarms()
    func saveAlarms()

    // Handle alarm firing
    func handleAlarmFired(alarmID: UUID)
    func dismissAlarm()
    func snoozeAlarm()
}
```

### 2. Alarm Editor View Model

```swift
// ViewModels/AlarmEditorViewModel.swift
import Foundation

class AlarmEditorViewModel: ObservableObject {
    @Published var hour: Int = 8
    @Published var minute: Int = 0
    @Published var label: String = "Alarm"
    @Published var repeatDays: Set<Weekday> = []
    @Published var snoozeEnabled: Bool = true

    var isEditing: Bool { existingAlarm != nil }
    private var existingAlarm: Alarm?

    init(alarm: Alarm? = nil) { ... }

    func createAlarm() -> Alarm

    // Quick repeat options
    func setDaily()
    func setWeekdays()
    func setWeekends()
    func setOnce()
}
```

## Views

### 1. Main Tab View

```swift
// Views/MainTabView.swift
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView()
                .tabItem {
                    Label("Clock", systemImage: "clock.fill")
                }
                .tag(0)

            AlarmListView()
                .tabItem {
                    Label("Alarms", systemImage: "alarm.fill")
                }
                .tag(1)
        }
    }
}
```

### 2. Alarm List View

```swift
// Views/AlarmListView.swift
import SwiftUI

struct AlarmListView: View {
    @StateObject private var viewModel = AlarmViewModel()
    @StateObject private var purchaseManager = PurchaseManager.shared

    var body: some View {
        NavigationStack {
            List {
                // PRO status banner (if not pro)
                if !purchaseManager.isPro {
                    ProBannerView(
                        alarmsUsed: viewModel.alarms.count,
                        limit: purchaseManager.freeAlarmLimit
                    )
                }

                // Alarm list
                ForEach(viewModel.alarms) { alarm in
                    AlarmRowView(alarm: alarm) {
                        viewModel.toggleAlarm(alarm)
                    } onTap: {
                        viewModel.editingAlarm = alarm
                        viewModel.showingEditor = true
                    }
                }
                .onDelete { indexSet in
                    // Delete alarm
                }
            }
            .navigationTitle("Alarms")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: viewModel.addButtonTapped) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingEditor) {
                AlarmEditorView(alarm: viewModel.editingAlarm) { alarm in
                    // Save alarm
                }
            }
            .sheet(isPresented: $viewModel.showingUpgrade) {
                UpgradeProView()
            }
            .fullScreenCover(item: $viewModel.firingAlarm) { alarm in
                AlarmFiringView(alarm: alarm) {
                    viewModel.dismissAlarm()
                } onSnooze: {
                    viewModel.snoozeAlarm()
                }
            }
        }
    }
}
```

### 3. Alarm Row View

```swift
// Views/AlarmRowView.swift
import SwiftUI

struct AlarmRowView: View {
    let alarm: Alarm
    let onToggle: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    // Time
                    Text(alarm.timeString)
                        .font(.system(size: 48, weight: .light))
                        .monospacedDigit()

                    // Label and repeat info
                    HStack {
                        Text(alarm.label)
                        if !alarm.repeatDays.isEmpty {
                            Text("•")
                            Text(alarm.repeatDescription)
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }

                Spacer()

                // Toggle
                Toggle("", isOn: Binding(
                    get: { alarm.isEnabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
            }
        }
        .buttonStyle(.plain)
        .opacity(alarm.isEnabled ? 1 : 0.5)
    }
}
```

### 4. Alarm Editor View

```swift
// Views/AlarmEditorView.swift
import SwiftUI

struct AlarmEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AlarmEditorViewModel
    let onSave: (Alarm) -> Void

    init(alarm: Alarm?, onSave: @escaping (Alarm) -> Void) {
        _viewModel = StateObject(wrappedValue: AlarmEditorViewModel(alarm: alarm))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                // Time picker
                Section {
                    DatePicker(
                        "Time",
                        selection: $viewModel.selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                }

                // Label
                Section {
                    TextField("Label", text: $viewModel.label)
                }

                // Repeat
                Section("Repeat") {
                    // Quick options
                    HStack {
                        QuickRepeatButton(title: "Once", isSelected: viewModel.repeatDays.isEmpty) {
                            viewModel.setOnce()
                        }
                        QuickRepeatButton(title: "Daily", isSelected: viewModel.repeatDays.count == 7) {
                            viewModel.setDaily()
                        }
                        QuickRepeatButton(title: "Weekdays", isSelected: viewModel.repeatDays == Weekday.weekdays) {
                            viewModel.setWeekdays()
                        }
                    }

                    // Custom day selection
                    ForEach(Weekday.allCases) { day in
                        Toggle(day.fullName, isOn: Binding(
                            get: { viewModel.repeatDays.contains(day) },
                            set: { isOn in
                                if isOn {
                                    viewModel.repeatDays.insert(day)
                                } else {
                                    viewModel.repeatDays.remove(day)
                                }
                            }
                        ))
                    }
                }

                // Snooze
                Section {
                    Toggle("Snooze", isOn: $viewModel.snoozeEnabled)
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Alarm" : "Add Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(viewModel.createAlarm())
                        dismiss()
                    }
                }
            }
        }
    }
}
```

### 5. Alarm Firing View

```swift
// Views/AlarmFiringView.swift
import SwiftUI

struct AlarmFiringView: View {
    let alarm: Alarm
    let onDismiss: () -> Void
    let onSnooze: () -> Void

    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Pulsing red background
            Color.red
                .ignoresSafeArea()
                .opacity(0.9)

            VStack(spacing: 40) {
                Spacer()

                // Alarm icon with animation
                Image(systemName: "alarm.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .modifier(ShakeEffect())

                // Current time (large)
                Text(currentTime.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 72, weight: .bold))
                    .foregroundColor(.white)

                // Alarm label
                Text(alarm.label)
                    .font(.title)
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                // Snooze button
                if alarm.snoozeEnabled {
                    Button(action: onSnooze) {
                        Text("Snooze (5 min)")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 40)
                }

                // Stop button
                Button(action: onDismiss) {
                    Text("Stop")
                        .font(.title.bold())
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onAppear {
            AlarmSoundPlayer.shared.startAlarm(soundName: alarm.soundName)
            // Announce time after brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                AlarmSoundPlayer.shared.speakTime()
            }
        }
        .onDisappear {
            AlarmSoundPlayer.shared.stopAlarm()
        }
    }
}
```

### 6. Upgrade Pro View

```swift
// Views/UpgradeProView.swift
import SwiftUI

struct UpgradeProView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeKit = StoreKitManager.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // PRO badge
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.yellow, .orange)

                Text("Upgrade to PRO")
                    .font(.largeTitle.bold())

                // Benefits list
                VStack(alignment: .leading, spacing: 16) {
                    BenefitRow(icon: "alarm.fill", text: "Up to 10 alarms")
                    BenefitRow(icon: "bell.badge.fill", text: "Priority support")
                    BenefitRow(icon: "heart.fill", text: "Support development")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)

                // Current usage
                Text("You're using 2 of 2 free alarms")
                    .foregroundColor(.secondary)

                Spacer()

                // Purchase button
                if let product = storeKit.products.first {
                    Button {
                        Task {
                            try? await storeKit.purchase(product)
                        }
                    } label: {
                        Text("Upgrade for \(product.displayPrice)")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(16)
                    }
                    .disabled(storeKit.isLoading)
                }

                // Restore purchases
                Button("Restore Purchases") {
                    Task {
                        await storeKit.restorePurchases()
                    }
                }
                .font(.subheadline)
                .padding(.bottom, 20)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                await storeKit.loadProducts()
            }
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
        }
    }
}
```

## App Entry Point Changes

```swift
// App/TalkingClockApp.swift
import SwiftUI

@main
struct TalkingClockApp: App {
    @StateObject private var alarmViewModel = AlarmViewModel()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(alarmViewModel)
                .onReceive(NotificationCenter.default.publisher(for: .alarmFired)) { notification in
                    if let alarmID = notification.userInfo?["alarmID"] as? UUID {
                        alarmViewModel.handleAlarmFired(alarmID: alarmID)
                    }
                }
        }
    }
}
```

## Alarm Sound Implementation

### Creating Loud Alarm Sound

**Option 1: Custom Sound File**
- Create/source a loud alarm sound (royalty-free)
- Export as CAF format: `afconvert -f caff -d LEI16 alarm.wav loud_alarm.caf`
- Add to project under `Resources/Sounds/`
- Maximum 30 seconds for notification sound

**Option 2: System Sound with Max Volume**
- Use `AudioServicesPlaySystemSound` with vibration
- Combine with `AVAudioPlayer` for extended alarm

### Audio Session Configuration

```swift
private func configureAudioSession() {
    do {
        let session = AVAudioSession.sharedInstance()

        // Playback category ignores silent switch
        try session.setCategory(
            .playback,
            mode: .default,
            options: [.duckOthers]
        )

        // Activate session
        try session.setActive(true)

    } catch {
        print("Audio session error: \(error)")
    }
}
```

### Volume Maximization

```swift
import MediaPlayer

private func setMaxVolume() {
    // Get current volume
    let volumeView = MPVolumeView()
    if let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
        originalVolume = slider.value
        slider.value = 1.0
    }
}
```

**Note**: Direct volume control may have App Store limitations. Alternative approach:
- Use `AVAudioPlayer` with `volume = 1.0`
- Play sound at maximum encoded volume
- Include UI prompt asking user to increase volume

## In-App Purchase Setup

### 1. App Store Connect Configuration

1. Go to App Store Connect > Your App > Features > In-App Purchases
2. Create new in-app purchase:
   - Type: Non-Consumable
   - Reference Name: Talking Clock PRO
   - Product ID: `com.yourcompany.talkingclock.pro`
   - Price: $2.99 (or your choice)
   - Display Name: "PRO Upgrade"
   - Description: "Unlock up to 10 alarms and support development"

### 2. Xcode Configuration

1. Add "In-App Purchase" capability in Signing & Capabilities
2. Create StoreKit Configuration file for testing (optional)

### 3. Product IDs

```swift
enum ProductID {
    static let pro = "com.yourcompany.talkingclock.pro"
}
```

## Notification Configuration

### Info.plist Additions

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>remote-notification</string>
</array>
```

### Notification Categories

```swift
func registerNotificationCategories() {
    let snoozeAction = UNNotificationAction(
        identifier: "SNOOZE_ACTION",
        title: "Snooze (5 min)",
        options: []
    )

    let stopAction = UNNotificationAction(
        identifier: "STOP_ACTION",
        title: "Stop",
        options: [.destructive, .foreground]
    )

    let alarmCategory = UNNotificationCategory(
        identifier: "ALARM_CATEGORY",
        actions: [snoozeAction, stopAction],
        intentIdentifiers: [],
        options: [.customDismissAction]
    )

    UNUserNotificationCenter.current().setNotificationCategories([alarmCategory])
}
```

### Critical Alerts (Optional - Requires Entitlement)

For truly loud alarms that bypass Do Not Disturb:
1. Request Critical Alert entitlement from Apple
2. Add to notification content: `content.interruptionLevel = .critical`

**Note**: Critical alerts require Apple approval and are typically only granted to health/safety apps.

## Persistence

### Alarm Storage

```swift
extension AlarmViewModel {
    private static let storageKey = "savedAlarms"

    func loadAlarms() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let alarms = try? JSONDecoder().decode([Alarm].self, from: data) else {
            return
        }
        self.alarms = alarms
    }

    func saveAlarms() {
        if let data = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
```

### PRO Status Storage

```swift
// Using Keychain for secure storage of purchase status
// Or rely on StoreKit 2's automatic entitlement checking
```

## Implementation Order

### Phase 1: Core Structure
1. [ ] Create `Alarm` and `Weekday` models
2. [ ] Create `MainTabView` with tab navigation
3. [ ] Move existing `ContentView` to Clock tab
4. [ ] Create basic `AlarmListView` (empty state)

### Phase 2: Alarm CRUD
5. [ ] Create `AlarmViewModel` with persistence
6. [ ] Create `AlarmRowView` component
7. [ ] Create `AlarmEditorView` with time picker
8. [ ] Implement add/edit/delete/toggle functionality

### Phase 3: Alarm Scheduling
9. [ ] Create `AlarmScheduler` service
10. [ ] Register notification categories
11. [ ] Implement alarm scheduling logic
12. [ ] Handle notification responses (snooze/stop)

### Phase 4: Alarm Firing
13. [ ] Create `AlarmSoundPlayer` service
14. [ ] Add/create loud alarm sound file
15. [ ] Create `AlarmFiringView` full-screen UI
16. [ ] Integrate time announcement on alarm fire

### Phase 5: Freemium Model
17. [ ] Create `PurchaseManager` with limits
18. [ ] Create `StoreKitManager` for IAP
19. [ ] Create `UpgradeProView`
20. [ ] Implement purchase flow
21. [ ] Add limit enforcement in alarm creation

### Phase 6: Polish
22. [ ] Add haptic feedback
23. [ ] Add alarm animations
24. [ ] Test all scenarios
25. [ ] Handle edge cases (app killed, device restart)

## Testing Checklist

### Alarm Functionality
- [ ] Create alarm and verify it fires at correct time
- [ ] Edit existing alarm
- [ ] Delete alarm
- [ ] Toggle alarm on/off
- [ ] Verify repeat options work (daily, weekdays, custom)
- [ ] Snooze functionality (fires again after 5 min)
- [ ] One-time alarm auto-disables after firing

### Sound & Volume
- [ ] Alarm is loud (maximum volume)
- [ ] Alarm overrides silent mode
- [ ] Time is announced after alarm starts
- [ ] Sound stops when alarm dismissed
- [ ] Sound stops when snoozed

### Freemium Model
- [ ] Can create 2 alarms for free
- [ ] 3rd alarm shows upgrade prompt
- [ ] Purchase flow works
- [ ] PRO status persists after restart
- [ ] Restore purchases works
- [ ] Can create up to 10 alarms with PRO

### Edge Cases
- [ ] App in background when alarm fires
- [ ] App terminated when alarm fires
- [ ] Device restarted (alarms persist)
- [ ] Multiple alarms at same time
- [ ] Alarm during Do Not Disturb

## UI Mockups

### Alarm List (Free User)
```
┌─────────────────────────────────┐
│  Alarms                      +  │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ ⭐ Upgrade to PRO           │ │
│ │ 2 of 2 free alarms used     │ │
│ └─────────────────────────────┘ │
│                                 │
│  7:00 AM                    ◉   │
│  Wake up • Weekdays             │
│                                 │
│  8:30 AM                    ○   │
│  Meeting • Mon, Wed, Fri        │
│                                 │
│                                 │
│                                 │
├─────────────────────────────────┤
│   🕐 Clock    |    ⏰ Alarms    │
└─────────────────────────────────┘
```

### Alarm Firing Screen
```
┌─────────────────────────────────┐
│                                 │
│            ⏰                   │
│         (shaking)               │
│                                 │
│          7:00 AM                │
│                                 │
│         Wake up                 │
│                                 │
│                                 │
│  ┌───────────────────────────┐  │
│  │     Snooze (5 min)        │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │         STOP              │  │
│  └───────────────────────────┘  │
│                                 │
└─────────────────────────────────┘
        (Red pulsing background)
```

### Upgrade PRO Screen
```
┌─────────────────────────────────┐
│  Cancel                         │
│                                 │
│            ⭐                   │
│                                 │
│     Upgrade to PRO              │
│                                 │
│  ┌───────────────────────────┐  │
│  │ ⏰ Up to 10 alarms        │  │
│  │ 🔔 Priority support       │  │
│  │ ❤️ Support development    │  │
│  └───────────────────────────┘  │
│                                 │
│  You're using 2 of 2 free       │
│  alarms                         │
│                                 │
│  ┌───────────────────────────┐  │
│  │    Upgrade for $2.99      │  │
│  └───────────────────────────┘  │
│                                 │
│      Restore Purchases          │
│                                 │
└─────────────────────────────────┘
```

## Notes & Considerations

### App Store Guidelines
- In-app purchases must provide clear value
- Cannot artificially limit free tier too severely
- Must allow restore purchases
- Cannot use external payment methods

### Limitations
- iOS limits local notifications to 64 pending
- Critical alerts require special entitlement
- Cannot guarantee alarm fires if app force-quit (mitigate with notifications)
- Volume control has limitations on iOS

### Future Enhancements
- Custom alarm sounds
- Gradually increasing volume
- Math problems to dismiss
- Spotify/Apple Music integration
- Widget showing next alarm
- Siri shortcuts
