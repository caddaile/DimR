import SwiftUI

struct ContentView: View {
    @Bindable var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle("Enabled", isOn: $appState.isEnabled)

            Toggle("Launch at Login", isOn: launchAtLoginBinding)

            if appState.loginItemRequiresApproval {
                Button("Approve in System Settings") {
                    appState.openLoginItemsSettings()
                }
                .font(.caption)
            }

            if let loginItemErrorMessage = appState.loginItemErrorMessage {
                Text(loginItemErrorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let settingsErrorMessage = appState.settingsErrorMessage {
                Text(settingsErrorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Opacity")
                    Spacer()
                    Text(appState.overlayOpacity, format: .percent.precision(.fractionLength(0)))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Slider(value: opacityBinding, in: 0.1...1.0, step: 0.05)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Idle Timeout")
                    Spacer()
                    Text(appState.idleTimeout, format: .number.precision(.fractionLength(0)))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    Text("sec")
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    Slider(value: idleTimeoutBinding, in: 5...600, step: 5)
                    TextField("Seconds", value: idleTimeoutBinding, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 72)
                }
            }

            Divider()

            Button("Quit DimR") {
                appState.quit()
            }
            .keyboardShortcut("q")
        }
        .padding(12)
        .frame(width: 260)
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { appState.launchAtLogin },
            set: { appState.setLaunchAtLogin($0) }
        )
    }

    private var opacityBinding: Binding<Double> {
        Binding(
            get: { appState.overlayOpacity },
            set: { appState.setOverlayOpacity($0) }
        )
    }

    private var idleTimeoutBinding: Binding<Double> {
        Binding(
            get: { appState.idleTimeout },
            set: { appState.setIdleTimeout($0) }
        )
    }
}

#Preview {
    ContentView(appState: AppState())
}
