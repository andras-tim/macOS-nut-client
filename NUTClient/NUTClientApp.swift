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
            .sink { [weak self] _ in
                self?.updateMenuIcon()
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
