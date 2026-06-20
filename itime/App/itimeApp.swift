import SwiftUI
import AppKit

@main
struct iTimeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarPopoverView()
                .environment(ConversionHistory.shared)
                .frame(width: 360)
        } label: {
            Image(systemName: "clock.arrow.circlepath")
                .accessibilityLabel("iTime 时间转换工具")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}
