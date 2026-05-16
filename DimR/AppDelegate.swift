import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Accessory apps stay out of the Dock and app switcher while still
        // allowing a MenuBarExtra-based interface.
        NSApp.setActivationPolicy(.accessory)
    }
}
