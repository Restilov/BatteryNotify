import AppKit

/// The low battery warning, drawn by the app itself.
///
/// A floating panel is used instead of a system notification: it needs no
/// permission, it never auto-hides, and it stays on top of full screen apps.
final class AlertPanel {
    private let onDismiss: () -> Void
    private var panel: NSPanel?
    private let messageLabel = NSTextField(labelWithString: "")

    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    var isVisible: Bool { panel?.isVisible ?? false }

    func show(percentage: Int) {
        let panel = self.panel ?? makePanel()
        self.panel = panel

        messageLabel.stringValue = "\(percentage)% remaining. Plug in the charger."

        guard !panel.isVisible else { return }

        moveToTopRight(panel)
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSSound.beep()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            panel.animator().alphaValue = 1
        }
    }

    func hide() {
        panel?.orderOut(nil)
    }

    // MARK: - Construction

    private func makePanel() -> NSPanel {
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 340, height: 116),
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered,
                            defer: false)
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true

        let background = NSVisualEffectView()
        background.material = .hudWindow
        background.blendingMode = .behindWindow
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = 14
        background.layer?.masksToBounds = true
        panel.contentView = background

        let icon = NSImageView()
        icon.image = NSImage(systemSymbolName: "battery.25percent", accessibilityDescription: nil)
        icon.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 26, weight: .regular)
        icon.contentTintColor = .systemRed

        let title = NSTextField(labelWithString: "Low Battery")
        title.font = .systemFont(ofSize: 14, weight: .semibold)

        messageLabel.font = .systemFont(ofSize: 12)
        messageLabel.textColor = .secondaryLabelColor

        let dismiss = NSButton(title: "Dismiss", target: self, action: #selector(dismissClicked))
        dismiss.bezelStyle = .rounded
        dismiss.controlSize = .regular

        for view in [icon, title, messageLabel, dismiss] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            background.addSubview(view)
        }

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 18),
            icon.topAnchor.constraint(equalTo: background.topAnchor, constant: 20),

            title.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 14),
            title.topAnchor.constraint(equalTo: background.topAnchor, constant: 20),
            title.trailingAnchor.constraint(lessThanOrEqualTo: background.trailingAnchor, constant: -18),

            messageLabel.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            messageLabel.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 4),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: background.trailingAnchor, constant: -18),

            dismiss.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -18),
            dismiss.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -16),
        ])

        return panel
    }

    private func moveToTopRight(_ panel: NSPanel) {
        guard let frame = (NSScreen.main ?? NSScreen.screens.first)?.visibleFrame else { return }
        let size = panel.frame.size
        panel.setFrameOrigin(NSPoint(x: frame.maxX - size.width - 16,
                                     y: frame.maxY - size.height - 16))
    }

    @objc private func dismissClicked() {
        hide()
        onDismiss()
    }
}
