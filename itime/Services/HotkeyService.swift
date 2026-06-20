import AppKit
import Carbon.HIToolbox

/// Manages global hotkey registration using Carbon API.
/// Carbon RegisterEventHotKey does NOT require Accessibility permission.
@MainActor
final class HotkeyService {
    static let shared = HotkeyService()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var currentCombo: KeyCombo = .default

    // Carbon signature for our hotkey
    private let hotKeySignature: UInt32 = 0x4954_4D45 // "ITME"

    // MARK: - Registration

    func registerCurrentHotkey() {
        let savedData = UserDefaults.standard.data(forKey: "hotkeyConfig")
        if let data = savedData, let config = try? JSONDecoder().decode(HotkeyConfig.self, from: data) {
            currentCombo = config.convertHotkey
        } else {
            currentCombo = .default
        }
        register(keyCombo: currentCombo)
    }

    func register(keyCombo: KeyCombo) {
        unregister()

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        // Install event handler
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData = userData else { return OSStatus(-9874) }
                let service = Unmanaged<HotkeyService>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async {
                    service.handleHotkeyPress()
                }
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandlerRef
        )

        guard status == noErr else { return }

        // Register the hotkey
        var hotKeyID = EventHotKeyID(signature: hotKeySignature, id: 1)
        RegisterEventHotKey(
            keyCombo.keyCode,
            keyCombo.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        currentCombo = keyCombo
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let ref = eventHandlerRef {
            RemoveEventHandler(ref)
            eventHandlerRef = nil
        }
    }

    func updateHotkey(to keyCombo: KeyCombo) {
        // Save to UserDefaults
        let config = HotkeyConfig(convertHotkey: keyCombo)
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: "hotkeyConfig")
        }
        register(keyCombo: keyCombo)
    }

    // MARK: - Hotkey Handler

    private func handleHotkeyPress() {
        Task { @MainActor in
            await performConversion()
        }
    }

    private func performConversion() async {
        // Try to get selected text first via synthetic ⌘C
        var textToConvert: String?

        if AXIsProcessTrusted() {
            textToConvert = await captureSelectedText()
        }

        // Fall back to clipboard
        if textToConvert == nil || textToConvert?.isEmpty == true {
            textToConvert = ClipboardService.shared.readText()
        }

        guard let text = textToConvert, !text.isEmpty else {
            ToastService.shared.show(input: "—", output: "剪贴板为空")
            return
        }

        // Determine output precision from settings
        let useMilliseconds = UserDefaults.standard.bool(forKey: "outputMilliseconds")
        let precision: OutputPrecision = useMilliseconds ? .milliseconds : .seconds

        // Perform conversion
        if let result = ConversionEngine.convert(text, outputPrecision: precision) {
            ClipboardService.shared.writeText(result.output)
            ToastService.shared.show(input: result.input, output: result.output)
            ConversionHistory.shared.add(result)
        } else {
            ToastService.shared.show(input: text, output: "未识别到有效时间")
        }
    }

    /// Simulate ⌘C to capture selected text from the active application.
    private func captureSelectedText() async -> String? {
        let pb = NSPasteboard.general
        let changeCountBefore = pb.changeCount

        // Post synthetic ⌘C
        let source = CGEventSource(stateID: .combinedSessionState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: false) else {
            return nil
        }
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)

        // Wait for clipboard to update
        try? await Task.sleep(for: .milliseconds(100))

        // Check if clipboard actually changed
        guard pb.changeCount != changeCountBefore else {
            return pb.string(forType: .string) // Return existing clipboard content
        }

        return pb.string(forType: .string)
    }
}
