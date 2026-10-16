//
//  NUTClientApp.swift
//  NUTClient
//
//  Created by Barna Fulop on 18.05.2026.
//
//
import SwiftUI
import AppKit
import Combine
import UserNotifications

@main
struct NUTClientNativeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            PreferencesView(client: appDelegate.sharedClient, state: appDelegate.sharedClient.state)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem!
    var trayMenuController: TrayMenuController!
    
    let upsState = UPSStateMachine()
    let powerNotifier = PowerNotifier()
    lazy var sharedClient: NUTClient = {
        let savedHost = UserDefaults.standard.string(forKey: "nutHost") ?? "127.0.0.1"
        let savedPort = UInt16(UserDefaults.standard.string(forKey: "nutPort") ?? "3493") ?? 3493
        let savedUPSName = UserDefaults.standard.string(forKey: "nutUPSName") ?? ""
        let savedUser = UserDefaults.standard.string(forKey: "nutUser")
        let savedPass = UserDefaults.standard.string(forKey: "nutPass")
        
        return NUTClient(
            state: upsState,
            host: savedHost,
            port: savedPort,
            upsName: savedUPSName.isEmpty ? "ups" : savedUPSName,
            username: savedUser?.isEmpty == false ? savedUser : nil,
            password: savedPass?.isEmpty == false ? savedPass : nil
        )
    }()
    
    // Used to observe background changes for the icon
    private var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(named: "icon.battery.bolt")
        }
        
        trayMenuController = TrayMenuController(state: upsState)
        statusItem.menu = trayMenuController.menu
        
        sharedClient.connect()
        upsState.$variables
            .receive(on: RunLoop.main)
            .sink { [weak self] variables in
                self?.updateMenuIcon()
                self?.powerNotifier.update(variables: variables)
            }
            .store(in: &cancellables)
    }
    
    private func updateMenuIcon() {
        if let button = statusItem.button {
            let iconName = upsState.isRunningOnBattery ? "icon.battery.exclamation" : "icon.battery.bolt"
            button.image = NSImage(named: iconName)
        }
    }
}

/// Posts a notification when the UPS status flags change: on battery, back on mains, low battery, forced shutdown.
/// Switched off with the `notifyPowerEvents` preference.
final class PowerNotifier {
    private var lastFlags: Set<String>?
    
    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    func update(variables: [String: String]) {
        guard let status = variables[UPSVariable.upsStatus.rawValue] else { return }
        let flags = Set(status.split(separator: " ").map(String.init))
        // At app start every flag counts as new, except a plain "back on mains".
        let previous = lastFlags ?? []
        lastFlags = flags
        guard UserDefaults.standard.object(forKey: "notifyPowerEvents") as? Bool ?? true else { return }
        
        let added = flags.subtracting(previous)
        let charge = variables[UPSVariable.batteryCharge.rawValue].map { "\($0) %" } ?? "unknown charge"
        let minutes = variables[UPSVariable.batteryRuntime.rawValue].flatMap { Double($0) }.map { "about \(Int($0) / 60) min" }
            ?? "unknown time"
        
        if added.contains("FSD") {
            post("Shutting down", "The UPS server ordered a shutdown. Save your work now.")
        } else if added.contains("LB") {
            post("UPS battery low", "Battery at \(charge), \(minutes) left. The computer will shut down soon.")
        } else if added.contains("OB") {
            post("Power failure", "Running on UPS battery: \(charge), \(minutes) left.")
        } else if added.contains("OL") && previous.contains("OB") {
            post("Power restored", "Back on mains power.")
        }
    }
    
    private func post(_ title: String, _ body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
