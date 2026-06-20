import AppKit
import SwiftUI

/// Manages the HUD toast notification using a floating NSPanel.
@MainActor
final class ToastService {
    static let shared = ToastService()

    private var toastWindow: ToastWindow?
    private var dismissTask: Task<Void, Never>?

    /// Show a toast with input → output message.
    func show(input: String, output: String) {
        // Cancel any existing dismiss timer
        dismissTask?.cancel()

        // Remove existing toast
        if let existing = toastWindow {
            existing.orderOut(nil)
        }

        // Create new toast
        let window = ToastWindow()
        let toastView = ToastView(input: input, output: output)
        let hostingView = NSHostingView(rootView: toastView)

        // Measure the content
        let fittingSize = hostingView.fittingSize
        let width = max(280, min(400, fittingSize.width + 8))
        let height = fittingSize.height + 4

        window.setContentSize(NSSize(width: width, height: height))
        window.contentView = hostingView

        // Position: centered horizontally, near top of screen
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - width / 2
        let y = screenFrame.maxY - 70 - height
        window.setFrameOrigin(NSPoint(x: x, y: y))

        window.orderFront(nil)
        window.alphaValue = 0

        // Fade in (< 300ms per design spec)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            window.animator().alphaValue = 1.0
        }

        // Announce to VoiceOver
        AccessibilityHelpers.announceToVoiceOver("\(input) 转换为 \(output)")

        toastWindow = window

        // Auto-dismiss after 2 seconds
        scheduleDismiss(window)
    }

    /// Show a simple message toast (no input→output format, just the message text).
    func showMessage(_ message: String) {
        // Cancel any existing dismiss timer
        dismissTask?.cancel()

        // Remove existing toast
        if let existing = toastWindow {
            existing.orderOut(nil)
        }

        // Create new toast
        let window = ToastWindow()
        let toastView = ToastView(message: message)
        let hostingView = NSHostingView(rootView: toastView)

        // Measure the content
        let fittingSize = hostingView.fittingSize
        let width = max(280, min(400, fittingSize.width + 8))
        let height = fittingSize.height + 4

        window.setContentSize(NSSize(width: width, height: height))
        window.contentView = hostingView

        // Position: centered horizontally, near top of screen
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - width / 2
        let y = screenFrame.maxY - 70 - height
        window.setFrameOrigin(NSPoint(x: x, y: y))

        window.orderFront(nil)
        window.alphaValue = 0

        // Fade in
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            window.animator().alphaValue = 1.0
        }

        // Announce to VoiceOver
        AccessibilityHelpers.announceToVoiceOver(message)

        toastWindow = window

        // Auto-dismiss after 2 seconds
        scheduleDismiss(window)
    }

    // MARK: - Private

    private func scheduleDismiss(_ window: ToastWindow) {
        dismissTask = Task { [weak self, weak window] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled, let window else { return }
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.2
                window.animator().alphaValue = 0
            }, completionHandler: {
                window.orderOut(nil)
                if self?.toastWindow === window {
                    self?.toastWindow = nil
                }
            })
        }
    }
}

// MARK: - Toast Window

private final class ToastWindow: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 44),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
        self.isMovableByWindowBackground = false
        self.hidesOnDeactivate = false
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
