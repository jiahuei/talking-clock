import AVFoundation
import AlarmCore
import CryptoKit
import Foundation

private enum AudioFailure: LocalizedError {
    case unavailable, tooLong, timedOut, busy
    var errorDescription: String? {
        switch self {
        case .unavailable: return "The speech sound could not be created. Try again with an installed English voice."
        case .tooLong: return "The spoken sound exceeded the alarm sound duration limit."
        case .timedOut: return "Creating the voice sound timed out. Please try again."
        case .busy: return "Wait for the current sound preview to finish preparing."
        }
    }
}

/// AVSpeechSynthesizer delivers buffers on its own queue. Serialize file access and completion.
private final class SpeechFileWriter: @unchecked Sendable {
    private let lock = NSLock()
    private let url: URL
    private var file: AVAudioFile?
    private var duration: Double = 0
    private var finished = false
    private let completion: (Result<URL, Error>) -> Void

    init(url: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        self.url = url
        self.completion = completion
    }

    func consume(_ buffer: AVAudioBuffer) {
        lock.lock()
        guard !finished else { lock.unlock(); return }
        do {
            guard let pcm = buffer as? AVAudioPCMBuffer else { throw AudioFailure.unavailable }
            if pcm.frameLength == 0 {
                guard file != nil else { throw AudioFailure.unavailable }
                finishLocked(.success(url))
                return
            }
            if file == nil {
                var settings = pcm.format.settings
                settings[AVFormatIDKey] = kAudioFormatLinearPCM
                settings[AVLinearPCMBitDepthKey] = 16
                settings[AVLinearPCMIsFloatKey] = false
                settings[AVLinearPCMIsBigEndianKey] = false
                settings[AVLinearPCMIsNonInterleaved] = false
                file = try AVAudioFile(forWriting: url, settings: settings,
                                       commonFormat: pcm.format.commonFormat, interleaved: pcm.format.isInterleaved)
                try writeChime(format: pcm.format)
            }
            duration += Double(pcm.frameLength) / pcm.format.sampleRate
            guard duration < 28 else { throw AudioFailure.tooLong }
            try file?.write(from: pcm)
            lock.unlock()
        } catch { finishLocked(.failure(error)) }
    }

    func timeout() {
        lock.lock()
        guard !finished else { lock.unlock(); return }
        finishLocked(.failure(AudioFailure.timedOut))
    }

    private func finishLocked(_ result: Result<URL, Error>) {
        finished = true
        file = nil // Close the CAF before AlarmKit receives its filename.
        if case .failure = result { try? FileManager.default.removeItem(at: url) }
        lock.unlock()
        completion(result)
    }

    private func writeChime(format: AVAudioFormat) throws {
        guard format.commonFormat == .pcmFormatFloat32, !format.isInterleaved,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(format.sampleRate)) else {
            throw AudioFailure.unavailable
        }
        buffer.frameLength = buffer.frameCapacity
        guard let channels = buffer.floatChannelData else { throw AudioFailure.unavailable }
        for frame in 0..<Int(buffer.frameLength) {
            let t = Double(frame) / format.sampleRate
            let local = t.truncatingRemainder(dividingBy: 0.4)
            let envelope = local < 0.24 && t < 0.8 ? sin(.pi * local / 0.24) : 0
            let value = Float(0.24 * envelope * sin(2 * .pi * 880 * t))
            for channel in 0..<Int(format.channelCount) { channels[channel][frame] = value }
        }
        try file?.write(from: buffer)
        duration += 1
    }
}

@MainActor final class AlarmAudio: NSObject, AVAudioPlayerDelegate, AVSpeechSynthesizerDelegate {
    private var renderer: AVSpeechSynthesizer?
    private let speaker = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?
    private var rendering = false

    override init() {
        super.init()
        speaker.delegate = self
    }

    func sound(for alarm: AlarmRecord) async throws -> String {
        let text = Self.phrase(hour: alarm.hour, minute: alarm.minute)
        let digest = SHA256.hash(data: Data("v1-en-US-\(text)".utf8)).map { String(format: "%02x", $0) }.joined()
        let name = "talking-clock-\(digest).caf"
        let directory = try FileManager.default.url(for: .libraryDirectory, in: .userDomainMask,
                                                    appropriateFor: nil, create: true).appendingPathComponent("Sounds")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let output = directory.appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: output.path),
           let file = try? AVAudioFile(forReading: output), file.length > 0 { return name }
        guard !rendering else { throw AudioFailure.busy }
        rendering = true
        defer { rendering = false; renderer = nil }
        let temporary = directory.appendingPathComponent("\(UUID().uuidString).caf")
        let synthesizer = AVSpeechSynthesizer()
        renderer = synthesizer
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.44
        utterance.postUtteranceDelay = 0.3
        do {
            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
                let writer = SpeechFileWriter(url: temporary) { continuation.resume(with: $0) }
                synthesizer.write(utterance) { writer.consume($0) }
                DispatchQueue.global().asyncAfter(deadline: .now() + 20) { writer.timeout() }
            }
            // A crash during synthesis leaves only an unreferenced temporary file.
            if FileManager.default.fileExists(atPath: output.path) { try FileManager.default.removeItem(at: output) }
            try FileManager.default.moveItem(at: temporary, to: output)
            try FileManager.default.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                                                  ofItemAtPath: output.path)
            return name
        } catch {
            synthesizer.stopSpeaking(at: .immediate)
            try? FileManager.default.removeItem(at: temporary)
            throw error
        }
    }

    func preview(_ alarm: AlarmRecord) async throws {
        guard alarm.announcesTime else { return }
        let name = try await sound(for: alarm)
        let library = try FileManager.default.url(for: .libraryDirectory, in: .userDomainMask,
                                                  appropriateFor: nil, create: false)
        stop()
        try activateSession()
        player = try AVAudioPlayer(contentsOf: library.appendingPathComponent("Sounds").appendingPathComponent(name))
        player?.delegate = self
        guard player?.play() == true else { stop(); throw AudioFailure.unavailable }
    }

    func speakNow() throws {
        stop()
        try activateSession()
        let now = Date()
        let utterance = AVSpeechUtterance(string: Self.phrase(hour: Calendar.current.component(.hour, from: now),
                                                           minute: Calendar.current.component(.minute, from: now)))
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speaker.speak(utterance)
    }

    func stop() {
        player?.stop()
        player = nil
        speaker.stopSpeaking(at: .immediate)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func activateSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try session.setActive(true)
    }

    private static func phrase(hour: Int, minute: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "h:mm a"
        let date = Calendar.current.date(from: DateComponents(year: 2001, month: 1, day: 1, hour: hour, minute: minute))!
        return "The time is \(formatter.string(from: date))."
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.stop() }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.stop() }
    }
}
