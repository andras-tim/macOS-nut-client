//
//  UPSVariable.swift
//  NUTClient
//
//  Created by Barna Fulop on 19.05.2026.
//
import Foundation

enum UPSVariable: String, CaseIterable {
    // Ambient
    case ambientTemperature = "ambient.temperature"
    case ambientTemperatureHigh = "ambient.temperature.high"
    
    // Battery
    case batteryCharge = "battery.charge"
    case batteryChargerStatus = "battery.charger.status"
    case batteryPacks = "battery.packs"
    case batteryRuntime = "battery.runtime"
    case batteryRuntimeLow = "battery.runtime.low"
    case batteryVoltage = "battery.voltage"
    
    // Device
    case deviceMfr = "device.mfr"
    case deviceModel = "device.model"
    case devicePart = "device.part"
    case deviceSerial = "device.serial"
    case deviceType = "device.type"
    
    // Driver
    case driverName = "driver.name"
    case driverParameterPollinterval = "driver.parameter.pollinterval"
    case driverParameterPort = "driver.parameter.port"
    case driverParameterSynchronous = "driver.parameter.synchronous"
    case driverVersion = "driver.version"
    case driverVersionInternal = "driver.version.internal"
    
    // Input
    case inputFrequency = "input.frequency"
    case inputFrequencyHigh = "input.frequency.high"
    case inputFrequencyLow = "input.frequency.low"
    case inputFrequencyNominal = "input.frequency.nominal"
    case inputTransferBoostHigh = "input.transfer.boost.high"
    case inputTransferHigh = "input.transfer.high"
    case inputTransferLow = "input.transfer.low"
    case inputTransferTrimLow = "input.transfer.trim.low"
    case inputVoltage = "input.voltage"
    case inputVoltageNominal = "input.voltage.nominal"
    
    // Outlets
    case outlet1DelayShutdown = "outlet.1.delay.shutdown"
    case outlet1DelayStart = "outlet.1.delay.start"
    case outlet1Id = "outlet.1.id"
    case outlet1Status = "outlet.1.status"
    
    case outlet2DelayShutdown = "outlet.2.delay.shutdown"
    case outlet2DelayStart = "outlet.2.delay.start"
    case outlet2Id = "outlet.2.id"
    case outlet2Status = "outlet.2.status"
    
    // Output
    case outputCurrent = "output.current"
    case outputCurrentNominal = "output.current.nominal"
    case outputFrequency = "output.frequency"
    case outputFrequencyNominal = "output.frequency.nominal"
    case outputPhases = "output.phases"
    case outputVoltage = "output.voltage"
    case outputVoltageNominal = "output.voltage.nominal"
    
    // UPS General
    case upsBeeperStatus = "ups.beeper.status"
    case upsDescription = "ups.description"
    case upsFirmware = "ups.firmware"
    case upsLoad = "ups.load"
    case upsMfr = "ups.mfr"
    case upsModel = "ups.model"
    case upsPower = "ups.power"
    case upsPowerNominal = "ups.power.nominal"
    case upsRealPower = "ups.realpower"
    case upsSerial = "ups.serial"
    case upsStatus = "ups.status"
    case upsTestResult = "ups.test.result"
}

extension UPSVariable {
    
    // MARK: - Display Name
    var displayName: String {
        switch self {
        // Ambient
        case .ambientTemperature: return String(localized: "Temperature")
        case .ambientTemperatureHigh: return String(localized: "High Temp Threshold")
            
        // Battery
        case .batteryCharge: return String(localized: "Charge Level")
        case .batteryChargerStatus: return String(localized: "Charger Status")
        case .batteryPacks: return String(localized: "External Packs")
        case .batteryRuntime: return String(localized: "Time Remaining")
        case .batteryRuntimeLow: return String(localized: "Low Battery Warning at")
        case .batteryVoltage: return String(localized: "Battery Voltage")
            
        // Device & Driver
        case .deviceMfr, .upsMfr: return String(localized: "Manufacturer")
        case .deviceModel, .upsModel: return String(localized: "Model")
        case .devicePart: return String(localized: "Part Number")
        case .deviceSerial, .upsSerial: return String(localized: "Serial Number")
        case .deviceType: return String(localized: "Device Type")
        case .driverName: return String(localized: "Driver")
        case .driverParameterPollinterval: return String(localized: "Poll Interval")
        case .driverParameterPort: return String(localized: "Port")
        case .driverParameterSynchronous: return String(localized: "Synchronous Mode")
        case .driverVersion: return String(localized: "Driver Version")
        case .driverVersionInternal: return String(localized: "Internal Version")
            
        // Input
        case .inputFrequency: return String(localized: "Input Frequency")
        case .inputFrequencyHigh: return String(localized: "Frequency High Limit")
        case .inputFrequencyLow: return String(localized: "Frequency Low Limit")
        case .inputFrequencyNominal: return String(localized: "Nominal Frequency")
        case .inputTransferBoostHigh: return String(localized: "Boost Transfer High")
        case .inputTransferHigh: return String(localized: "High Voltage Transfer")
        case .inputTransferLow: return String(localized: "Low Voltage Transfer")
        case .inputTransferTrimLow: return String(localized: "Trim Transfer Low")
        case .inputVoltage: return String(localized: "Input Voltage")
        case .inputVoltageNominal: return String(localized: "Nominal Input")
            
        // Outlets
        case .outlet1DelayShutdown, .outlet2DelayShutdown: return String(localized: "Shutdown Delay")
        case .outlet1DelayStart, .outlet2DelayStart: return String(localized: "Startup Delay")
        case .outlet1Id, .outlet2Id: return String(localized: "Outlet ID")
        case .outlet1Status, .outlet2Status: return String(localized: "Outlet Status")
            
        // Output
        case .outputCurrent: return String(localized: "Output Current")
        case .outputCurrentNominal: return String(localized: "Nominal Current")
        case .outputFrequency: return String(localized: "Output Frequency")
        case .outputFrequencyNominal: return String(localized: "Nominal Frequency")
        case .outputPhases: return String(localized: "Phases")
        case .outputVoltage: return String(localized: "Output Voltage")
        case .outputVoltageNominal: return String(localized: "Nominal Output")
            
        // UPS General
        case .upsBeeperStatus: return String(localized: "Beeper Status")
        case .upsDescription: return String(localized: "Description")
        case .upsFirmware: return String(localized: "Firmware")
        case .upsLoad: return String(localized: "Current Load")
        case .upsPower: return String(localized: "Apparent Power")
        case .upsPowerNominal: return String(localized: "Nominal Power")
        case .upsRealPower: return String(localized: "Real Power")
        case .upsStatus: return String(localized: "UPS Status")
        case .upsTestResult: return String(localized: "Last Self-Test")
        }
    }
    
    // MARK: - Value Formatting
    func formatLiveValue(_ value: String) -> String {
        // exit for empty or invalid data so we don't return things like "-- V"
        guard !value.isEmpty, value != "--" else { return "--" }
        
        switch self {
            
        // Voltages (V)
        case .inputVoltage, .inputVoltageNominal, .inputTransferHigh, .inputTransferLow,
             .inputTransferBoostHigh, .inputTransferTrimLow, .outputVoltage,
             .outputVoltageNominal, .batteryVoltage:
            return "\(value) V"
            
        // Frequencies (Hz)
        case .inputFrequency, .inputFrequencyHigh, .inputFrequencyLow, .inputFrequencyNominal,
             .outputFrequency, .outputFrequencyNominal:
            if let frequency = Double(value) {
                let formattedFrequency = String(format: "%.2f", frequency/10)
                return "\(formattedFrequency) Hz"
            }
            return "\(value) Hz"
            
        // Percentages (%)
        case .batteryCharge, .upsLoad:
            return "\(value)%"
            
        // Temperatures (°C) - NUT natively reports in Celsius
        case .ambientTemperature, .ambientTemperatureHigh:
            return "\(value) °C"
            
        // Power (W / VA)
        case .upsRealPower:
            return "\(value) W"
        case .upsPower, .upsPowerNominal:
            return "\(value) VA"
            
        // Current (A)
        case .outputCurrent, .outputCurrentNominal:
            return "\(value) A"
            
        // Time / Runtime Handling (Seconds -> Hours/Minutes)
        case .batteryRuntime, .batteryRuntimeLow, .outlet1DelayShutdown,
             .outlet1DelayStart, .outlet2DelayShutdown, .outlet2DelayStart:
            if let seconds = Int(value) {
                let minutes = seconds / 60
                
                if minutes > 0 {
                    return String(localized: "\(minutes) min")
                } else {
                    return String(localized: "\(seconds) sec")
                }
            }
            return "\(value) s"
            
        // Humanize the raw UPS status abbreviations
        case .upsStatus:
            let upperVal = value.uppercased()
            if upperVal.contains("OL") { return String(localized: "Online (AC Power)") }
            if upperVal.contains("OB") { return String(localized: "On Battery") }
            if upperVal.contains("LB") { return String(localized: "Low Battery!") }
            if upperVal.contains("CHRG") { return String(localized: "Charging") }
            if upperVal.contains("DISCHRG") { return String(localized: "Discharging") }
            return value
            
        // Beeper
        case .upsBeeperStatus:
            return value.lowercased() == "enabled" ? String(localized: "Active") : String(localized: "Muted")
            
        // Default (Strings, IDs, Models) - Return exactly as received
        default:
            return value
        }
    }
}

// Define the UI Groups
enum UPSCategory: String, CaseIterable {
    case ambient = "Ambient"
    case battery = "Battery"
    case device = "Device Info"
    case driver = "Driver Data"
    case input = "Input"
    case outlets = "Outlets"
    case output = "Output"
    case upsGeneral = "UPS General"

    var title: String {
        switch self {
        case .ambient: return String(localized: "Ambient")
        case .battery: return String(localized: "Battery")
        case .device: return String(localized: "Device Info")
        case .driver: return String(localized: "Driver Data")
        case .input: return String(localized: "Input")
        case .outlets: return String(localized: "Outlets")
        case .output: return String(localized: "Output")
        case .upsGeneral: return String(localized: "UPS General")
        }
    }
}

// Add a category mapper to your existing UPSVariable enum
extension UPSVariable {
    var category: UPSCategory {
        if rawValue.hasPrefix("ambient") { return .ambient }
        if rawValue.hasPrefix("battery") { return .battery }
        if rawValue.hasPrefix("device") { return .device }
        if rawValue.hasPrefix("driver") { return .driver }
        if rawValue.hasPrefix("input") { return .input }
        if rawValue.hasPrefix("outlet") { return .outlets }
        if rawValue.hasPrefix("output") { return .output }
        return .upsGeneral
    }
}


