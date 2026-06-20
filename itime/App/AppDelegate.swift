import AppKit
import Carbon.HIToolbox

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let servicesProvider = ServicesMenuProvider()

    func applicationWillFinishLaunching(_ notification: Notification) {
        // Register Services Menu — must happen before app finishes launching
        // so the services system can pick up the provider during launch.
        NSApp.servicesProvider = servicesProvider
        // Register the service port under the name declared in Info.plist (NSPortName = "iTime")
        // so that the macOS Services dispatcher can find the running provider.
        NSRegisterServicesProvider(servicesProvider, "iTime")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Suppress Dock icon (belt-and-suspenders with LSUIElement)
        NSApp.setActivationPolicy(.accessory)

        // Refresh dynamic services registration so this app's NSServices entries
        // are visible in the system Services menu without a logout.
        NSUpdateDynamicServices()

        // Initialize system integrations
        ClipboardService.shared.startMonitoringIfNeeded()
        HotkeyService.shared.registerCurrentHotkey()

        // Register for termination to clean up
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate(_:)),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }

    @objc func applicationWillTerminate(_ notification: Notification) {
        HotkeyService.shared.unregister()
        ClipboardService.shared.stopMonitoring()
    }
}
