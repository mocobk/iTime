import SwiftUI
import ServiceManagement
import Carbon.HIToolbox

@MainActor
struct SettingsView: View {
    var onDismiss: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @AppStorage("outputMilliseconds") private var outputMilliseconds = false
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @State private var isRecordingHotkey = false
    @State private var hotkeyDisplay: String = "⌥⌘T"
    @State private var hotkeyMonitor: Any?

    var body: some View {
        VStack(spacing: 0) {
            // Title bar with Done button
            HStack {
                Text("设置")
                    .font(.headline)
                Spacer()
                Button("完成") {
                    stopRecording()
                    if let onDismiss {
                        onDismiss()
                    } else {
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            Form {
                // Hotkey section
                Section("快捷键") {
                    HStack {
                        Text("全局快捷键")
                        Spacer()
                        Button {
                            if isRecordingHotkey {
                                stopRecording()
                            } else {
                                startRecording()
                            }
                        } label: {
                            Text(isRecordingHotkey ? "按下快捷键..." : hotkeyDisplay)
                                .font(.system(.body, design: .monospaced))
                                .frame(minWidth: 80)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(isRecordingHotkey ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(isRecordingHotkey ? Color.accentColor : Color.clear, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("录制全局快捷键")
                    }
                }

                // Conversion section
                Section("转换") {
                    Toggle("输出精度：毫秒", isOn: $outputMilliseconds)
                    Toggle("使用本地时区", isOn: .constant(true))
                        .disabled(true)
                }

                // General section
                Section("通用") {
                    Toggle("开机自启动", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { _, newValue in
                            toggleLaunchAtLogin(newValue)
                        }
                }

                // About section
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("作者")
                        Spacer()
                        Text("mocobk")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("邮箱")
                        Spacer()
                        Text("mailmzb@qq.com")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 360, height: 400)
        .onAppear {
            loadCurrentHotkey()
        }
    }

    // MARK: - Hotkey Recording

    private func startRecording() {
        isRecordingHotkey = true
        hotkeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard !modifiers.isEmpty else { return event }

            let keyCode = UInt32(event.keyCode)
            var carbonModifiers: UInt32 = 0
            if modifiers.contains(.command) { carbonModifiers |= UInt32(cmdKey) }
            if modifiers.contains(.option) { carbonModifiers |= UInt32(optionKey) }
            if modifiers.contains(.shift) { carbonModifiers |= UInt32(shiftKey) }
            if modifiers.contains(.control) { carbonModifiers |= UInt32(controlKey) }

            let combo = KeyCombo(keyCode: keyCode, modifiers: carbonModifiers)
            HotkeyService.shared.updateHotkey(to: combo)
            hotkeyDisplay = combo.displayString
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        isRecordingHotkey = false
        if let monitor = hotkeyMonitor {
            NSEvent.removeMonitor(monitor)
            hotkeyMonitor = nil
        }
    }

    private func loadCurrentHotkey() {
        if let data = UserDefaults.standard.data(forKey: "hotkeyConfig"),
           let config = try? JSONDecoder().decode(HotkeyConfig.self, from: data) {
            hotkeyDisplay = config.convertHotkey.displayString
        }
    }

    /// Read version: prefer Bundle (runtime), fallback to VERSION file (dev time).
    private var appVersion: String {
        let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        if let bundleVersion, !bundleVersion.isEmpty, bundleVersion != "$(MARKETING_VERSION)" {
            return bundleVersion
        }
        // Fallback: read VERSION file for dev-time or SPM builds
        if let url = Bundle.main.url(forResource: "VERSION", withExtension: nil),
           let content = try? String(contentsOf: url) {
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return "1.0.0"
    }

    // MARK: - Launch at Login

    private func toggleLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Silently fail
        }
    }
}
