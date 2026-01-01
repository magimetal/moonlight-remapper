import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @State private var launchAtLogin: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "keyboard.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("Moonlight Remapper")
                    .font(.headline)
            }
            .padding(.bottom, 4)

            Divider()

            // Permission warning if needed
            if !appState.hasAccessibilityPermission {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Accessibility permission required")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button("Grant Permission") {
                    appState.requestAccessibilityPermission()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Divider()
            }

            // Main toggle
            Toggle(isOn: $appState.isEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enable Remapping")
                        .font(.body)
                    Text("Left CMD -> Left CTRL in Moonlight")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
            .disabled(!appState.hasAccessibilityPermission)

            Divider()

            // Moonlight status
            HStack(spacing: 8) {
                Circle()
                    .fill(appState.isMoonlightFrontmost ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(moonlightStatusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Launch at login
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .toggleStyle(.switch)
                .onChange(of: launchAtLogin) { _, newValue in
                    LaunchAtLoginManager.setEnabled(newValue)
                }

            Divider()

            // Overall status
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Quit button
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(16)
        .frame(width: 280)
        .onAppear {
            launchAtLogin = LaunchAtLoginManager.isEnabled
            appState.checkAccessibilityPermission()
        }
    }

    private var moonlightStatusText: String {
        if appState.isMoonlightFrontmost {
            return "Moonlight is active"
        } else {
            return "Moonlight is not frontmost"
        }
    }

    private var statusColor: Color {
        if !appState.hasAccessibilityPermission {
            return .orange
        } else if appState.isEnabled && appState.isMoonlightFrontmost {
            return .green
        } else if appState.isEnabled {
            return .blue
        } else {
            return .gray
        }
    }

    private var statusText: String {
        if !appState.hasAccessibilityPermission {
            return "Waiting for permission..."
        } else if appState.isEnabled && appState.isMoonlightFrontmost {
            return "Active - remapping Left CMD to CTRL"
        } else if appState.isEnabled {
            return "Enabled - waiting for Moonlight"
        } else {
            return "Disabled"
        }
    }
}
