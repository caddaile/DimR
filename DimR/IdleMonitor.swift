import CoreGraphics
import Foundation

@MainActor
final class IdleMonitor {
    var isEnabled = true
    var idleTimeout: TimeInterval
    var onDimmedStateChange: ((Bool) -> Void)?

    private var timer: Timer?

    init(idleTimeout: TimeInterval) {
        self.idleTimeout = idleTimeout
    }

    deinit {
        timer?.invalidate()
    }

    func start() {
        guard timer == nil else { return }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pollIdleTime()
            }
        }
        timer?.tolerance = 0.2
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        onDimmedStateChange?(false)
    }

    private func pollIdleTime() {
        guard isEnabled else {
            onDimmedStateChange?(false)
            return
        }

        // kCGAnyInputEventType asks Core Graphics for the last keyboard, mouse,
        // or tablet input event in the combined user session.
        let anyInputEventType = CGEventType(rawValue: ~0)!
        let idleSeconds = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: anyInputEventType
        )

        onDimmedStateChange?(idleSeconds >= idleTimeout)
    }
}
