import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private static let thresholdKey = "lowBatteryThreshold"
    private static let thresholdChoices = [10, 15, 20, 25, 30]

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var monitor: PowerMonitor?
    private var alert: AlertPanel?
    private var statusMenuItem: NSMenuItem?
    private var thresholdItems: [NSMenuItem] = []
    private var launchAtLoginItem: NSMenuItem?

    private var dismissedAtPercentage: Int? = nil
    private var lastKnownPercentage = 0

    private var threshold: Int {
        get {
            let stored = UserDefaults.standard.integer(forKey: Self.thresholdKey)
            return Self.thresholdChoices.contains(stored) ? stored : 20
        }
        set { UserDefaults.standard.set(newValue, forKey: Self.thresholdKey) }
    }

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        alert = AlertPanel { [weak self] in
            self?.dismissedAtPercentage = self?.lastKnownPercentage
        }

        buildMenu()

        monitor = PowerMonitor { [weak self] state in
            self?.handle(state)
        }
        monitor?.start()
    }

    // MARK: - Battery state

    private func handle(_ state: PowerMonitor.State) {
        lastKnownPercentage = state.percentage
        updateStatusItem(state)

        if state.isPluggedIn || state.percentage > threshold {
            // Charger connected, or back above the threshold: the warning is no
            // longer relevant, so take it off the screen by itself.
            alert?.hide()
            dismissedAtPercentage = nil
        } else if let dismissed = dismissedAtPercentage, state.percentage > dismissed - 5 {
        } else {
            dismissedAtPercentage = nil
            alert?.show(percentage: state.percentage)
        }
    }

    private func updateStatusItem(_ state: PowerMonitor.State) {
        let name: String
        if state.isPluggedIn {
            name = "battery.100percent.bolt"
        } else {
            switch state.percentage {
            case ..<13: name = "battery.0percent"
            case ..<38: name = "battery.25percent"
            case ..<63: name = "battery.50percent"
            case ..<88: name = "battery.75percent"
            default: name = "battery.100percent"
            }
        }

        if let image = NSImage(systemSymbolName: name, accessibilityDescription: "Battery") {
            image.isTemplate = true
            statusItem.button?.image = image
            statusItem.button?.title = ""
        } else {
            statusItem.button?.image = nil
            statusItem.button?.title = "\(state.percentage)%"
        }

        let source = state.isPluggedIn ? "Charging" : "On battery"
        statusMenuItem?.title = "\(state.percentage)% · \(source)"
    }

    // MARK: - Menu

    private func buildMenu() {
        let menu = NSMenu()
        menu.delegate = self

        let status = NSMenuItem(title: "Reading battery…", action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        statusMenuItem = status

        menu.addItem(.separator())

        let header = NSMenuItem(title: "Low battery alert", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)

        thresholdItems = Self.thresholdChoices.map { value in
            let item = NSMenuItem(title: "\(value)%", action: #selector(selectThreshold(_:)), keyEquivalent: "")
            item.target = self
            item.tag = value
            item.state = value == threshold ? .on : .off
            menu.addItem(item)
            return item
        }

        menu.addItem(.separator())

        let launch = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launch.target = self
        menu.addItem(launch)
        launchAtLoginItem = launch

        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        launchAtLoginItem?.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    @objc private func selectThreshold(_ sender: NSMenuItem) {
        threshold = sender.tag
        for item in thresholdItems {
            item.state = item.tag == sender.tag ? .on : .off
        }
        dismissedAtPercentage = nil
        monitor?.reevaluate()
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Could not change the login item"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
        launchAtLoginItem?.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }
}
