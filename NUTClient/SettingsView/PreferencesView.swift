//
//  PreferencesView.swift
//  NUTClient
//
//  Created by Barna Fulop on 18.05.2026.
//
import SwiftUI
import Combine

class AppPreferences: ObservableObject {
    @Published var selectedVars: [String] { didSet { UserDefaults.standard.set(selectedVars, forKey: "SelectedUPSVars") } }
    
    @Published var host: String { didSet { UserDefaults.standard.set(host, forKey: "nutHost") } }
    @Published var port: String { didSet { UserDefaults.standard.set(port, forKey: "nutPort") } }
    @Published var upsName: String { didSet { UserDefaults.standard.set(upsName, forKey: "nutUPSName") } }
    @Published var username: String { didSet { UserDefaults.standard.set(username, forKey: "nutUser") } }
    @Published var password: String { didSet { UserDefaults.standard.set(password, forKey: "nutPass") } }
    
    @Published var notifyPowerEvents: Bool { didSet { UserDefaults.standard.set(notifyPowerEvents, forKey: "notifyPowerEvents") } }
    @Published var menuBarStatus: String { didSet { UserDefaults.standard.set(menuBarStatus, forKey: "menuBarStatus") } }
    
    init() {
        self.selectedVars = UserDefaults.standard.stringArray(forKey: "SelectedUPSVars") ?? ["ups.status", "battery.charge", "ups.load"]
        self.host = UserDefaults.standard.string(forKey: "nutHost") ?? "127.0.0.1"
        self.port = UserDefaults.standard.string(forKey: "nutPort") ?? "3493"
        self.upsName = UserDefaults.standard.string(forKey: "nutUPSName") ?? "ups"
        self.username = UserDefaults.standard.string(forKey: "nutUser") ?? ""
        self.password = UserDefaults.standard.string(forKey: "nutPass") ?? ""
        
        self.notifyPowerEvents = UserDefaults.standard.object(forKey: "notifyPowerEvents") as? Bool ?? true
        self.menuBarStatus = UPSStateMachine.StatusDisplay.current.rawValue
    }
}

struct PreferencesView: View {
    var client: NUTClient
    @ObservedObject var state: UPSStateMachine
    @StateObject private var prefs = AppPreferences()
    
    @State private var expandedGroups: [UPSCategory: Bool] = [:]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // --- App Behavior Settings ---
            GroupBox("App Behavior") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Notify on power failure, restore and shutdown", isOn: $prefs.notifyPowerEvents)
                        .toggleStyle(.switch)
                    
                    Picker("Show Status in Menu Bar", selection: $prefs.menuBarStatus) {
                        ForEach(UPSStateMachine.StatusDisplay.allCases, id: \.rawValue) { option in
                            Text(option.title).tag(option.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .fixedSize()
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // --- Connection Settings ---
            GroupBox("Connection Settings") {
                VStack(spacing: 12) {
                    HStack {
                        TextField("IP Address / Host", text: $prefs.host)
                            .textFieldStyle(.roundedBorder)
                        TextField("Port", text: $prefs.port)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                    
                    TextField("UPS Name (as in the server's ups.conf)", text: $prefs.upsName)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack {
                        TextField("Username (Optional)", text: $prefs.username)
                            .textFieldStyle(.roundedBorder)
                        SecureField("Password (Optional)", text: $prefs.password)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        // Status Indicator
                        Circle()
                            .fill(state.isConnected ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(state.isConnected ? "Connected" : "Disconnected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Connect / Disconnect Buttons
                        if state.isConnected {
                            Button("Disconnect") {
                                client.disconnect()
                            }
                        } else {
                            Button("Connect") {
                                client.applySettingsAndConnect(
                                    host: prefs.host,
                                    port: prefs.port,
                                    upsName: prefs.upsName,
                                    username: prefs.username,
                                    password: prefs.password
                                )
                            }
                            .buttonStyle(.borderedProminent) // Makes the connect button blue/primary
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(8)
            }
            
            // --- Variables Selection ---
            VStack(alignment: .leading) {
                Text("Menu Bar Layout:")
                    .font(.headline)
                Text("Select the variables you want grouped in the menu bar.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if state.variables.isEmpty {
                    VStack {
                        Spacer()
                        Text("Connect to a UPS to see available variables.")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(UPSCategory.allCases, id: \.self) { category in
                            let availableVars = UPSVariable.allCases.filter { $0.category == category && state.variables.keys.contains($0.rawValue) }
                            if !availableVars.isEmpty {
                                categoryGroup(category: category, variables: availableVars)
                            }
                        }
                    }
                    .listStyle(.sidebar)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .frame(width: 480, height: 650)
    }
    
    @ViewBuilder
    private func categoryGroup(category: UPSCategory, variables: [UPSVariable]) -> some View {
        let isExpanded = Binding(
            get: { expandedGroups[category, default: true] },
            set: { expandedGroups[category] = $0 }
        )
        
        let allSelected = variables.allSatisfy { prefs.selectedVars.contains($0.rawValue) }
        let someSelected = variables.contains { prefs.selectedVars.contains($0.rawValue) } && !allSelected
        
        let groupBinding = Binding<Bool>(
            get: { allSelected },
            set: { selectAll in
                for variable in variables {
                    if selectAll {
                        if !prefs.selectedVars.contains(variable.rawValue) { prefs.selectedVars.append(variable.rawValue) }
                    } else {
                        prefs.selectedVars.removeAll { $0 == variable.rawValue }
                    }
                }
            }
        )
        
        DisclosureGroup(isExpanded: isExpanded) {
            ForEach(variables, id: \.rawValue) { variable in
                let isSelected = Binding<Bool>(
                    get: { prefs.selectedVars.contains(variable.rawValue) },
                    set: { isToggled in
                        if isToggled { prefs.selectedVars.append(variable.rawValue) }
                        else { prefs.selectedVars.removeAll { $0 == variable.rawValue } }
                    }
                )
                
                Toggle(isOn: isSelected) {
                    HStack {
                        Text(variable.displayName)
                        Spacer()
                        Text(variable.formatLiveValue(state.variables[variable.rawValue] ?? ""))
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.checkbox)
                .padding(.leading, 8)
                .padding(.vertical, 2)
            }
        } label: {
            Toggle(isOn: groupBinding) {
                Text(category.rawValue)
                    .font(.system(size: 14, weight: .semibold))
            }
            .toggleStyle(MixedStateToggleStyle(isMixed: someSelected))
        }
    }
}

struct MixedStateToggleStyle: ToggleStyle {
    var isMixed: Bool
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: isMixed ? "minus.square.fill" : (configuration.isOn ? "checkmark.square.fill" : "square"))
                .foregroundColor(isMixed || configuration.isOn ? .accentColor : .secondary)
                .onTapGesture { configuration.isOn.toggle() }
            configuration.label
        }
    }
}
