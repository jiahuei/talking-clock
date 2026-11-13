#if DEBUG
    import AVFoundation
    import ActivityKit
    import AlarmCore
    import Observation
    import SwiftUI

    /// Deliberately isolated from production sessions: the issue requires hardware evidence before adoption.
    @MainActor @Observable final class BackgroundSpeechSpike {
        static let shared = BackgroundSpeechSpike()
        private(set) var running = false
        private(set) var preparing = false
        private(set) var message = "Not tested on a physical device."
        private let engine = AVAudioEngine()
        private let silence = AVAudioPlayerNode()
        private let speech = AVAudioPlayerNode()
        private var activity: Activity<AnnouncementActivity>?
        private var worker: Task<Void, Never>?
        private var stopObserver: NSObjectProtocol?

        private init() {
            stopObserver = NotificationCenter.default.addObserver(
                forName: Notification.Name("StopAnnouncementSpike"), object: nil, queue: .main
            ) { _ in Task { @MainActor in BackgroundSpeechSpike.shared.stop() } }
        }

        func start(audio: AlarmAudio) {
            guard !preparing, !running else { return }
            preparing = true
            worker = Task {
                defer { preparing = false }
                do {
                    let library = try FileManager.default.url(
                        for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    var events: [(Date, AVAudioFile)] = []
                    var boundary = IntervalScheduler.nextClock(after: Date(), minutes: 5)!
                    // Pre-render a bounded 70-minute experiment. Production replenishment is intentionally gated.
                    for _ in 0..<14 {
                        try Task.checkCancellation()
                        let phrase = SpokenTime.clock(
                            hour: Calendar.current.component(.hour, from: boundary),
                            minute: Calendar.current.component(.minute, from: boundary))
                        let name = try await audio.sound(text: phrase)
                        let file = try AVAudioFile(
                            forReading: library.appendingPathComponent("Sounds").appendingPathComponent(name))
                        events.append((boundary, file))
                        boundary = IntervalScheduler.nextClock(after: boundary, minutes: 5)!
                    }
                    try Task.checkCancellation()
                    events.removeAll { $0.0 <= Date().addingTimeInterval(2) }
                    guard let first = events.first else { return }
                    let format = first.1.processingFormat
                    guard
                        let quiet = AVAudioPCMBuffer(
                            pcmFormat: format, frameCapacity: AVAudioFrameCount(format.sampleRate))
                    else { throw CocoaError(.fileReadUnknown) }
                    quiet.frameLength = quiet.frameCapacity
                    for buffer in UnsafeMutableAudioBufferListPointer(quiet.mutableAudioBufferList) {
                        if let bytes = buffer.mData { memset(bytes, 0, Int(buffer.mDataByteSize)) }
                    }
                    engine.attach(silence)
                    engine.attach(speech)
                    engine.connect(silence, to: engine.mainMixerNode, format: format)
                    engine.connect(speech, to: engine.mainMixerNode, format: format)
                    let session = AVAudioSession.sharedInstance()
                    try session.setCategory(.playback, mode: .voicePrompt, options: [.mixWithOthers])
                    try session.setActive(true)
                    // Choose the non-awaiting overload: the entire programme is queued before playback starts.
                    silence.scheduleBuffer(quiet, at: nil, options: .loops, completionHandler: nil)
                    let starts = Date().addingTimeInterval(1)
                    let hostStart = mach_absolute_time() + AVAudioTime.hostTime(forSeconds: 1)
                    for (date, file) in events {
                        guard file.processingFormat == format else { throw CocoaError(.fileReadCorruptFile) }
                        let offset = AVAudioFramePosition(date.timeIntervalSince(starts) * format.sampleRate)
                        speech.scheduleFile(
                            file, at: AVAudioTime(sampleTime: offset, atRate: format.sampleRate), completionHandler: nil
                        )
                    }
                    activity = try Activity.request(
                        attributes: AnnouncementActivity(title: "Background speech experiment"),
                        content: ActivityContent(
                            state: AnnouncementActivity.ContentState(nextAnnouncement: first.0), staleDate: nil),
                        pushType: nil)
                    try engine.start()
                    silence.play(at: AVAudioTime(hostTime: hostStart))
                    speech.play(at: AVAudioTime(hostTime: hostStart))
                    running = true
                    message = "70-minute programme scheduled. Record timing and other-audio restoration on hardware."
                    for (index, event) in events.enumerated() {
                        try await Task.sleep(for: .seconds(max(0, event.0.timeIntervalSinceNow)))
                        try Task.checkCancellation()
                        try session.setCategory(
                            .playback, mode: .voicePrompt,
                            options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
                        try await Task.sleep(
                            for: .seconds(Double(event.1.length) / event.1.processingFormat.sampleRate))
                        try session.setCategory(.playback, mode: .voicePrompt, options: [.mixWithOthers])
                        if index + 1 < events.count {
                            await activity?.update(
                                ActivityContent(
                                    state: AnnouncementActivity.ContentState(nextAnnouncement: events[index + 1].0),
                                    staleDate: nil))
                        }
                    }
                    stop()
                    message = "Programme ended. Device measurements still need review."
                } catch {
                    stop()
                    if !(error is CancellationError) { message = error.localizedDescription }
                }
            }
        }

        func stop() {
            worker?.cancel()
            worker = nil
            silence.stop()
            speech.stop()
            engine.stop()
            if engine.attachedNodes.contains(silence) { engine.detach(silence) }
            if engine.attachedNodes.contains(speech) { engine.detach(speech) }
            running = false
            if let activity {
                self.activity = nil
                Task { await activity.end(nil, dismissalPolicy: .immediate) }
            }
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    struct BackgroundSpeechSpikeView: View {
        let audio: AlarmAudio
        @State private var spike = BackgroundSpeechSpike.shared
        var body: some View {
            Form {
                Section("Background speech experiment") {
                    Text(
                        "Development spike only. Start explicitly, lock for at least an hour, and measure each five-minute boundary. Repeat with music, silent switch and Bluetooth. Silent gaps are part of the experiment; this is not an approved production background mode."
                    )
                    Text(spike.message)
                    Button(spike.preparing ? "Preparing…" : "Start 70-minute experiment") { spike.start(audio: audio) }
                        .disabled(spike.running || spike.preparing)
                    Button("Stop experiment", role: .destructive) { spike.stop() }
                }
            }
        }
    }
#endif
