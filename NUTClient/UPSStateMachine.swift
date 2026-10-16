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
    
    // MARK: - Helper Methods
    func getValue(for variable: UPSVariable) -> String? {
        return variables[variable.rawValue]
    }
}
