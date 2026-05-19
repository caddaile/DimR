import AppKit

@MainActor
final class OverlayManager {
    private var currentOpacity = 0.0
    private var windows: [NSWindow] = []
    private var isVisible = false
    private var screenChangeObserver: NSObjectProtocol?

    init() {
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.rebuildWindowsIfVisible()
            }
        }
    }

    deinit {
        if let screenChangeObserver {
            NotificationCenter.default.removeObserver(screenChangeObserver)
        }
    }

    func setOpacity(_ value: Double, animated: Bool) {
        let opacity = min(max(value, 0.0), 1.0)
        currentOpacity = opacity

        guard opacity > 0.0 else {
            hide(animated: animated)
            return
        }

        showIfNeeded()
        animateWindows(to: opacity, duration: animated ? 0.18 : 0.0)
    }

    func hide(animated: Bool = true) {
        guard isVisible else { return }

        currentOpacity = 0.0
        isVisible = false

        NSAnimationContext.runAnimationGroup { context in
            context.duration = animated ? 0.15 : 0.0
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            windows.forEach { $0.animator().alphaValue = 0.0 }
        } completionHandler: { [windows] in
            windows.forEach { $0.orderOut(nil) }
        }
    }

    private func showIfNeeded() {
        guard !isVisible else { return }

        isVisible = true
        rebuildWindows()

        for window in windows {
            window.alphaValue = 0.0
            window.orderFrontRegardless()
        }
    }

    private func animateWindows(to opacity: Double, duration: TimeInterval) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            windows.forEach { $0.animator().alphaValue = opacity }
        }
    }

    private func rebuildWindowsIfVisible() {
        guard isVisible else { return }

        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        rebuildWindows()

        windows.forEach {
            $0.alphaValue = currentOpacity
            $0.orderFrontRegardless()
        }
    }

    private func rebuildWindows() {
        windows = NSScreen.screens.map(makeOverlayWindow)
    }

    private func makeOverlayWindow(for screen: NSScreen) -> NSWindow {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )

        // A borderless AppKit window gives precise control over macOS window
        // levels, click-through behavior, and capture sharing policy.
        window.backgroundColor = .black
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.sharingType = .none
        window.level = .screenSaver
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .ignoresCycle,
            .stationary
        ]
        window.isReleasedWhenClosed = false

        return window
    }
}
