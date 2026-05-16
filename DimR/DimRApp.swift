import SwiftUI

@main
struct DimRApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            ContentView(appState: appState)
        } label: {
            Image(systemName: "moon.fill")
                .accessibilityLabel("DimR")
        }
        .menuBarExtraStyle(.window)
    }
}
