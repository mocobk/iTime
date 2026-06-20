import SwiftUI
import ServiceManagement
import Carbon.HIToolbox

struct SettingsView: View {
    var onDismiss: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @AppStorage("outputMilliseconds") private var outputMilliseconds = false
    @AppStorage("clipboardMonitorEnabled") private var clipboardMonitorEnabled = false
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

                // Clipboard section
                Section("剪贴板") {
                    Toggle("后台剪贴板监听", isOn: $clipboardMonitorEnabled)
                        .onChange(of: clipboardMonitorEnabled) { _, newValue in
                            if newValue {
                                ClipboardService.shared.startMonitoring()
                            } else {
                                ClipboardService.shared.stopMonitoring()
                            }
                        }

                    if clipboardMonitorEnabled {
                        Text("检测到时间相关文本时自动弹出转换结果，不会自动覆盖剪贴板")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // General section
                Section("通用") {
                    Toggle("开机自启动", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { _, newValue in
                            toggleLaunchAtLogin(newValue)
                        }

                    HStack {
                        Text("版本")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
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
