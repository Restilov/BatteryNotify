import Foundation
import IOKit.ps

/// Event-driven battery monitor.
///
/// Uses IOKit's power-source run loop source instead of a timer, so nothing
/// runs until the charge level or the power adapter state actually changes.
final class PowerMonitor {
    struct State: Equatable {
        let percentage: Int
        let isPluggedIn: Bool
    }

    private let onChange: (State) -> Void
    private var state: State?
    private var source: CFRunLoopSource?

    init(onChange: @escaping (State) -> Void) {
        self.onChange = onChange
    }

    func start() {
        let context = Unmanaged.passUnretained(self).toOpaque()
        let callback: IOPowerSourceCallbackType = { context in
            guard let context else { return }
            Unmanaged<PowerMonitor>.fromOpaque(context).takeUnretainedValue().refresh()
        }

        if let source = IOPSNotificationCreateRunLoopSource(callback, context)?.takeRetainedValue() {
            self.source = source
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        }

        refresh()
    }

    /// Re-emits the current state without waiting for a hardware change,
    /// e.g. after the user picked a different threshold.
    func reevaluate() {
        guard let state else { return }
        onChange(state)
    }

    private func refresh() {
        guard let new = Self.readState(), new != state else { return }
        state = new
        onChange(new)
    }

    private static func readState() -> State? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef]
        else { return nil }

        for source in sources {
            guard let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any],
                  info[kIOPSTypeKey] as? String == kIOPSInternalBatteryType,
                  let current = info[kIOPSCurrentCapacityKey] as? Int,
                  let capacity = info[kIOPSMaxCapacityKey] as? Int, capacity > 0
            else { continue }

            let percentage = Int((Double(current) / Double(capacity) * 100).rounded())
            let isPluggedIn = info[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue
            return State(percentage: percentage, isPluggedIn: isPluggedIn)
        }

        return nil
    }
}
