//
//  UPSStateMachine.swift
//  NUTClient
//
//  Created by Barna Fulop on 19.05.2026.
//
import Foundation
import Combine

class UPSStateMachine: ObservableObject {
    @Published var isConnected: Bool = false
    /// macOS (15+) blocks the connection until the user allows Local Network access for this app.
    @Published var localNetworkDenied: Bool = false
    /// Why the app is not connected (network error, Local Network access, a server ERR reply); nil when fine.
    @Published var connectionError: String?
    @Published var hostString: String = ""
    @Published var variables: [String: String] = [:]
    
    var currentStatus: String {
        variables[UPSVariable.upsStatus.rawValue] ?? "Unknown"
    }
    
    var isRunningOnBattery: Bool {
        currentStatus.contains("OB")
    }
    
    var isBatteryLow: Bool {
        currentStatus.contains("LB")
    }
    
    var loadPercentage: String {
        variables[UPSVariable.upsLoad.rawValue] ?? "--"
    }
    
    var batteryCharge: String {
        variables[UPSVariable.batteryCharge.rawValue] ?? "--"
    }
    
    var allKeysSorted: [String] {
        variables.keys.sorted()
    }
    
    // MARK: - Power state (shared by the menu bar item, its tooltip and the menu header)
    
    enum PowerState {
        case disconnected, charged, charging, discharging, critical
    }
    
    /// What the menu bar shows next to the icon.
    enum StatusDisplay: String, CaseIterable {
        case never, discharging, activity, always
        
        var title: String {
            switch self {
            case .never: return "Never"
            case .discharging: return "Discharging"
            case .activity: return "Charging & Discharging"
            case .always: return "Always"
            }
        }
        
        static var current: StatusDisplay {
            StatusDisplay(rawValue: UserDefaults.standard.string(forKey: "menuBarStatus") ?? "") ?? .discharging
        }
    }
    
    var statusFlags: Set<String> {
        Set(currentStatus.split(separator: " ").map(String.init))
    }
    
    var chargeValue: Double? { variables[UPSVariable.batteryCharge.rawValue].flatMap { Double($0) } }
    var runtimeValue: Double? { variables[UPSVariable.batteryRuntime.rawValue].flatMap { Double($0) } }
    var runtimeLowValue: Double? { variables[UPSVariable.batteryRuntimeLow.rawValue].flatMap { Double($0) } }
    
    /// Charging and discharging come from OL/OB (+ CHRG), not from DISCHRG: some APC units report "OL DISCHRG"
    /// on mains at 100 %.
    var powerState: PowerState {
        guard isConnected, variables[UPSVariable.upsStatus.rawValue] != nil else { return .disconnected }
        let flags = statusFlags
        if flags.contains("FSD") || flags.contains("LB") { return .critical }
        if flags.contains("OB") {
            // close to the shutdown: the runtime reached the server's low-battery point
            if let runtime = runtimeValue, let low = runtimeLowValue, runtime <= low { return .critical }
            return .discharging
        }
        return flags.contains("CHRG") ? .charging : .charged
    }
    
    /// A horizontal battery filled to the charge.
    var batterySymbolName: String {
        switch chargeValue ?? 100 {
        case ..<13: return "battery.0"
        case ..<38: return "battery.25"
        case ..<63: return "battery.50"
        case ..<88: return "battery.75"
        default: return "battery.100"
        }
    }
    
    /// SF Symbol for the state; when disconnected the caller adds a question mark beside it.
    var iconSymbolName: String {
        switch powerState {
        case .charged: return "powerplug"
        case .charging: return "battery.100.bolt"
        case .discharging, .critical, .disconnected: return batterySymbolName
        }
    }
    
    var stateTitle: String {
        switch powerState {
        case .disconnected: return "Not Connected"
        case .charged: return "On Mains, Charged"
        case .charging: return "On Mains, Charging"
        case .discharging: return "Running on Battery"
        case .critical: return "Battery Nearly Empty"
        }
    }
    
    var percentText: String? { chargeValue.map { "\(Int($0))%" } }
    var minutesText: String? { runtimeValue.map { String(format: "%d mins", Int($0) / 60) } }
    
    /// Text beside the menu bar icon. Never shows a disconnection: that is an error, shown by the icon and tooltip.
    func statusText(_ display: StatusDisplay) -> String {
        switch powerState {
        case .disconnected:
            return ""
        case .discharging, .critical:
            guard display != .never else { return "" }
            return [percentText, minutesText].compactMap { $0 }.joined(separator: " ")
        case .charging:
            guard display == .activity || display == .always else { return "" }
            return percentText ?? ""
        case .charged:
            guard display == .always else { return "" }
            return percentText ?? ""
        }
    }
    
    /// "Not connected to <host>: <reason>", for the tooltip and the menu.
    var connectionErrorText: String {
        let reason = localNetworkDenied ? "Local Network access needed" : (connectionError ?? "no connection")
        return "Not connected to \(hostString): \(reason)"
    }
    
    // MARK: - Helper Methods
    func getValue(for variable: UPSVariable) -> String? {
        return variables[variable.rawValue]
    }
}
