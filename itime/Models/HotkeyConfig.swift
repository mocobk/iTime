import Foundation
import Carbon.HIToolbox

/// A keyboard shortcut combination (key code + modifiers).
struct KeyCombo: Sendable, Equatable, Codable {
    let keyCode: UInt32
    let modifiers: UInt32

    /// Default: Option+Command+T
    static let `default` = KeyCombo(
        keyCode: UInt32(kVK_ANSI_T),
        modifiers: UInt32(optionKey | cmdKey)
    )

    /// Human-readable display string like "⌥⌘T"
    var displayString: String {
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }

        let keyChar = Self.keyCodeToString(keyCode)
        parts.append(keyChar)
        return parts.joined()
    }

    /// Convert Carbon virtual key code to a display character.
    static func keyCodeToString(_ code: UInt32) -> String {
        let map: [UInt32: String] = [
            0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F",
            0x04: "H", 0x05: "G", 0x06: "Z", 0x07: "X",
            0x08: "C", 0x09: "V", 0x0B: "B", 0x0C: "Q",
            0x0D: "W", 0x0E: "E", 0x0F: "R", 0x10: "Y",
            0x11: "T", 0x12: "1", 0x13: "2", 0x14: "3",
            0x15: "4", 0x16: "6", 0x17: "5", 0x18: "=",
            0x19: "9", 0x1A: "7", 0x1B: "-", 0x1C: "8",
            0x1D: "0", 0x1E: "]", 0x1F: "O", 0x20: "U",
            0x21: "[", 0x22: "I", 0x23: "P", 0x25: "L",
            0x26: "J", 0x28: "K", 0x2C: "/", 0x2D: "N",
            0x2E: "M", 0x31: "Space", 0x24: "Return",
            0x30: "Tab", 0x33: "Delete", 0x35: "Esc",
        ]
        return map[code] ?? "?\(code)"
    }
}

/// Hotkey configuration holder.
struct HotkeyConfig: Sendable, Equatable, Codable {
    var convertHotkey: KeyCombo = .default
}
