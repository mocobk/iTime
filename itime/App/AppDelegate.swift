import AppKit
import SwiftUI
import Carbon.HIToolbox

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let servicesProvider = ServicesMenuProvider()

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!

    func applicationWillFinishLaunching(_ notification: Notification) {
        // Register Services Menu — must happen before app finishes launching
        NSApp.servicesProvider = servicesProvider
        NSRegisterServicesProvider(servicesProvider, "iTime")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Suppress Dock icon (belt-and-suspenders with LSUIElement)
        NSApp.setActivationPolicy(.accessory)

        // Refresh dynamic services registration
        NSUpdateDynamicServices()

        // Initialize system integrations
        HotkeyService.shared.registerCurrentHotkey()

        // Create status bar item
        setupStatusItem()

        // Create popover
        setupPopover()

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
    }

    // MARK: - Status Bar Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "clock.arrow.circlepath",
                               accessibilityDescription: "iTime 时间转换工具")
        button.image?.size = NSSize(width: 18, height: 18)
        button.target = self
        button.action = #selector(statusBarButtonClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 460)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarPopoverView()
                .environment(ConversionHistory.shared)
        )
    }

    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            togglePopover()
            return
        }

        if event.type == .rightMouseUp {
            showRightClickMenu(sender)
        } else {
            togglePopover()
        }
    }

    // MARK: - Popover

    private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Right-Click Menu

    private func showRightClickMenu(_ button: NSStatusBarButton) {
        let menu = NSMenu()

        // Use the system appearance setting (from System Settings), not the menu bar's
        // effective appearance which can be dark due to wallpaper regardless of system setting
        menu.appearance = Self.systemAppearance

        let showItem = NSMenuItem(title: "显示窗口", action: #selector(showPopoverAction), keyEquivalent: "")
        showItem.target = self
        menu.addItem(showItem)

        let settingsItem = NSMenuItem(title: "设置", action: #selector(openSettings), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)

        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 2), in: button)
    }

    @objc private func showPopoverAction() {
        showPopover()
    }

    @objc private func openSettings() {
        // Close popover first if shown (to reset state cleanly)
        if popover.isShown {
            popover.performClose(nil)
        }
        // Set state to show settings in popover
        AppState.shared.showSettings = true
        // Show popover with settings view
        showPopover()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - System Appearance

    /// Returns the actual system appearance (light/dark) based on System Settings,
    /// NOT the menu bar's effective appearance which can be dark due to wallpaper
    /// regardless of the system setting.
    private static var systemAppearance: NSAppearance {
        let defaults = UserDefaults.standard
        // If "Auto" mode is enabled, fall back to NSApp.effectiveAppearance
        // (which correctly reflects the time-of-day based appearance)
        if defaults.bool(forKey: "AppleInterfaceStyleSwitchesAutomatically") {
            return NSApp.effectiveAppearance
        }
        // Manual mode: AppleInterfaceStyle is "Dark" for dark, absent/nil for light
        if defaults.string(forKey: "AppleInterfaceStyle") == "Dark" {
            return NSAppearance(named: .darkAqua)!
        }
        return NSAppearance(named: .aqua)!
    }
}
