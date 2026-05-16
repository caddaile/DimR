import AppKit

@MainActor
final class BrightnessKeyMonitor {
    enum Direction {
        case up
        case down
    }

    var onBrightnessKey: ((Direction) -> Void)?

    private var localMonitor: Any?
    private var globalMonitor: Any?

    func start() {
        guard localMonitor == nil, globalMonitor == nil else { return }

        // Brightness keys arrive as system-defined auxiliary control events.
        // A local monitor can consume them while DimR is active; a global monitor
        // observes them while DimR is in the background.
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .systemDefined) { [weak self] event in
            guard let self, handle(event) else { return event }
            return nil
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .systemDefined) { [weak self] event in
            _ = self?.handle(event)
        }
    }

    func stop() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }

        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }

        localMonitor = nil
        globalMonitor = nil
    }

    private func handle(_ event: NSEvent) -> Bool {
        guard event.subtype.rawValue == 8 else { return false }

        let keyCode = (event.data1 & 0xFFFF0000) >> 16
        let keyState = (event.data1 & 0x0000FF00) >> 8
        let isKeyDown = keyState == 0x0A

        guard isKeyDown else { return false }

        switch keyCode {
        case 2:
            onBrightnessKey?(.up)
            return true
        case 3:
            onBrightnessKey?(.down)
            return true
        default:
            return false
        }
    }
}
