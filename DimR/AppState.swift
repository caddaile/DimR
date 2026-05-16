import AppKit
import Observation
import ServiceManagement

@MainActor
@Observable
final class AppState {
    var isEnabled = true {
        didSet {
            idleMonitor.isEnabled = isEnabled

            if !isEnabled {
                setDimmed(false)
            }

            saveSettings()
        }
    }

    private(set) var overlayOpacity = 0.7
    private(set) var idleTimeout = 60.0
    private(set) var isDimmed = false
    private(set) var launchAtLogin = false
    private(set) var loginItemRequiresApproval = false
    private(set) var loginItemErrorMessage: String?
    private(set) var settingsErrorMessage: String?

    @ObservationIgnored private let overlayManager: OverlayManager
    @ObservationIgnored private let idleMonitor: IdleMonitor
    @ObservationIgnored private let loginItemService = SMAppService.mainApp
    @ObservationIgnored private let settingsStore: SettingsStore

    init() {
        let settingsStore = SettingsStore()
        let settings = settingsStore.load()
        let overlayManager = OverlayManager()
        let idleMonitor = IdleMonitor(idleTimeout: settings.idleTimeout.clamped(to: 5.0...3600.0))

        self.settingsStore = settingsStore
        self.overlayManager = overlayManager
        self.idleMonitor = idleMonitor
        self.isEnabled = settings.isEnabled
        self.overlayOpacity = settings.overlayOpacity.clamped(to: 0.1...1.0)
        self.idleTimeout = settings.idleTimeout.clamped(to: 5.0...3600.0)

        overlayManager.setOpacity(overlayOpacity)
        idleMonitor.isEnabled = isEnabled
        idleMonitor.onDimmedStateChange = { [weak self] shouldDim in
            self?.setDimmed(shouldDim)
        }
        idleMonitor.start()
        refreshLoginItemStatus()
    }

    func setOverlayOpacity(_ value: Double) {
        overlayOpacity = value.clamped(to: 0.1...1.0)
        overlayManager.setOpacity(overlayOpacity)
        saveSettings()
    }

    func setIdleTimeout(_ value: Double) {
        idleTimeout = value.clamped(to: 5.0...3600.0)
        idleMonitor.idleTimeout = idleTimeout
        saveSettings()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        loginItemErrorMessage = nil

        do {
            if enabled {
                try loginItemService.register()
            } else {
                try loginItemService.unregister()
            }
        } catch {
            loginItemErrorMessage = error.localizedDescription
        }

        refreshLoginItemStatus()
    }

    func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    func quit() {
        overlayManager.hide()
        NSApp.terminate(nil)
    }

    private func refreshLoginItemStatus() {
        let status = loginItemService.status
        launchAtLogin = status == .enabled || status == .requiresApproval
        loginItemRequiresApproval = status == .requiresApproval
    }

    private func saveSettings() {
        let settings = AppSettings(
            isEnabled: isEnabled,
            overlayOpacity: overlayOpacity,
            idleTimeout: idleTimeout
        )

        do {
            try settingsStore.save(settings)
            settingsErrorMessage = nil
        } catch {
            settingsErrorMessage = "Could not save settings: \(error.localizedDescription)"
        }
    }

    private func setDimmed(_ shouldDim: Bool) {
        guard isDimmed != shouldDim else { return }

        isDimmed = shouldDim

        if shouldDim {
            overlayManager.show()
        } else {
            overlayManager.hide()
        }
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
