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
    private var localNetworkAlertShown = false
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        updateMenuIcon()
        
        trayMenuController = TrayMenuController(state: upsState)
        statusItem.menu = trayMenuController.menu
        
        sharedClient.connect()
        // DispatchQueue.main, not RunLoop.main: the RunLoop scheduler runs only in the default mode, so while the menu
        // is open (event tracking mode) the icon and the power notifications would wait until it closes.
        // The menu bar text switches live from Preferences.
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuIcon()
            }
            .store(in: &cancellables)
        
        upsState.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuIcon()
            }
            .store(in: &cancellables)
        
        upsState.$variables
            .receive(on: DispatchQueue.main)
            .sink { [weak self] variables in
                self?.updateMenuIcon()
                self?.powerNotifier.update(variables: variables)
            }
            .store(in: &cancellables)
        
        upsState.$localNetworkDenied
            .removeDuplicates()
            .filter { $0 }
            // RunLoop.main on purpose: the modal alert waits until the menu is closed
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.offerLocalNetworkSettings()
            }
            .store(in: &cancellables)
    }
    
    /// macOS asks for Local Network access only once; after a denial (or a missed prompt) only Settings can grant it.
    private func offerLocalNetworkSettings() {
        guard !localNetworkAlertShown else { return }
        localNetworkAlertShown = true
        
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = String(localized: "Local Network access needed")
        alert.informativeText = String(localized: """
            macOS blocks NUT Client from reaching the UPS server \(upsState.hostString). \
            Switch on NUTClient in System Settings > Privacy & Security > Local Network; \
            the connection then starts by itself.
            """)
        alert.addButton(withTitle: String(localized: "Open Settings"))
        alert.addButton(withTitle: String(localized: "Later"))
        if alert.runModal() == .alertFirstButtonReturn,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocalNetwork") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func updateMenuIcon() {
        guard let button = statusItem.button else { return }
        let powerState = upsState.powerState
        
        // Template images follow the light/dark menu bar; red only close to the shutdown.
        button.image = powerState == .disconnected
            ? Self.symbolWithQuestionMark(upsState.iconSymbolName)
            : Self.symbol(upsState.iconSymbolName)
        button.imagePosition = .imageLeft
        let color: NSColor? = powerState == .critical ? .systemRed : nil
        button.contentTintColor = color
        
        let status = upsState.statusText(.current)
        button.attributedTitle = NSAttributedString(string: status.isEmpty ? "" : " " + status, attributes: [
            .font: NSFont.menuBarFont(ofSize: 0),
            .foregroundColor: color ?? NSColor.labelColor
        ])
        
        button.toolTip = powerState == .disconnected
            ? upsState.connectionErrorText
            : ([upsState.stateTitle] + [upsState.percentText, upsState.minutesText].compactMap { $0 }).joined(separator: ", ")
    }
    
    static func symbol(_ name: String) -> NSImage? {
        let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)
            ?? NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: nil)
        image?.isTemplate = true
        return image
    }
    
    /// The state symbol with a question mark beside it: not connected, the values may be stale.
    static func symbolWithQuestionMark(_ name: String) -> NSImage? {
        guard let base = symbol(name), let mark = symbol("questionmark") else { return symbol(name) }
        let size = NSSize(width: base.size.width + 1 + mark.size.width * 0.8,
                          height: max(base.size.height, mark.size.height))
        let image = NSImage(size: size, flipped: false) { _ in
            base.draw(in: NSRect(x: 0, y: (size.height - base.size.height) / 2,
                                 width: base.size.width, height: base.size.height))
            let markSize = NSSize(width: mark.size.width * 0.8, height: mark.size.height * 0.8)
            mark.draw(in: NSRect(x: base.size.width + 1, y: (size.height - markSize.height) / 2,
                                 width: markSize.width, height: markSize.height))
            return true
        }
        image.isTemplate = true
        return image
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
        let charge = variables[UPSVariable.batteryCharge.rawValue].map { "\($0)%" } ?? String(localized: "unknown charge")
        let minutes = variables[UPSVariable.batteryRuntime.rawValue].flatMap { Double($0) }.map { String(localized: "about \(Int($0) / 60) min") }
            ?? String(localized: "unknown time")
        
        if added.contains("FSD") {
            post(String(localized: "Shutting down"), String(localized: "The UPS server ordered a shutdown. Save your work now."))
        } else if added.contains("LB") {
            post(String(localized: "UPS battery low"),
                 String(localized: "Battery at \(charge), \(minutes) left. The computer will shut down soon."))
        } else if added.contains("OB") {
            post(String(localized: "Power failure"), String(localized: "Running on UPS battery: \(charge), \(minutes) left."))
        } else if added.contains("OL") && previous.contains("OB") {
            post(String(localized: "Power restored"), String(localized: "Back on mains power."))
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
