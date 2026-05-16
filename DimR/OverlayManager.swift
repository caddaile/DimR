import AppKit

@MainActor
final class OverlayManager {
    private var opacity = 0.7
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

    func setOpacity(_ value: Double) {
        opacity = min(max(value, 0.1), 1.0)

        if isVisible {
            windows.forEach { $0.alphaValue = opacity }
        }
    }

    func show() {
        guard !isVisible else { return }

        isVisible = true
        rebuildWindows()

        for window in windows {
            window.alphaValue = 0.0
            window.orderFrontRegardless()
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            windows.forEach { $0.animator().alphaValue = opacity }
        }
    }

    func hide() {
        guard isVisible else { return }

        isVisible = false

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            windows.forEach { $0.animator().alphaValue = 0.0 }
        } completionHandler: { [windows] in
            windows.forEach { $0.orderOut(nil) }
        }
    }

    private func rebuildWindowsIfVisible() {
        guard isVisible else { return }

        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        rebuildWindows()

        windows.forEach {
            $0.alphaValue = opacity
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
        // levels and click-through behavior, which SwiftUI windows do not expose.
        window.backgroundColor = .black
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
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
