#if canImport(AlarmKit)
    import AlarmKit
    import Foundation

    /// Shared with the countdown widget so AlarmKit can find its Live Activity presentation.
    public struct TimerMetadata: AlarmMetadata {
        public init() {}
    }
#endif
