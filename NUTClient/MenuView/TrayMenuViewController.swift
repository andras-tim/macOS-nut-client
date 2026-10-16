//
//  TrayMenuViewController.swift
//  NUTClient
//
//  Created by Barna Fulop on 20.05.2026.
//
import AppKit
import SwiftUI

class TrayMenuController: NSObject, NSMenuDelegate {
    let menu: NSMenu
    private let viewModel: TrayMenuViewModel
        
    init(state: UPSStateMachine) {
        self.viewModel = TrayMenuViewModel(state: state)
        self.menu = NSMenu()
        
        super.init()
        self.menu.delegate = self
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()
        
        // --- swiftui header ---
        let headerView = HeaderView(state: viewModel.state)
        let headerController = NSHostingController(rootView: headerView)
        headerController.view.frame.size = NSSize(width: 300, height: 155)
        
        let headerMenuItem = NSMenuItem()
        headerMenuItem.view = headerController.view
        menu.addItem(headerMenuItem)
        
        // --- dynamic Body ---
        let sections = viewModel.buildMenuData()
        
        if sections.isEmpty {
            let emptyItem = NSMenuItem(title: "No variables selected.", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for section in sections {
                menu.addItem(NSMenuItem.separator())
                
                // group Header
                let headerItem = NSMenuItem()
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 13, weight: .bold),
                    .foregroundColor: NSColor.secondaryLabelColor
                ]
                headerItem.attributedTitle = NSAttributedString(string: section.title, attributes: attrs)
                headerItem.isEnabled = false
                menu.addItem(headerItem)
                
                // group Items
                for row in section.items {
                    let item = NSMenuItem(title: row.displayTitle, action: nil, keyEquivalent: "")
                    // Disabled keeps the row unclickable; the explicit colour keeps it readable (not dimmed).
                    item.attributedTitle = NSAttributedString(string: row.displayTitle, attributes: [
                        .font: NSFont.menuFont(ofSize: 0),
                        .foregroundColor: NSColor.labelColor
                    ])
                    item.isEnabled = false
                    item.indentationLevel = 1
                    menu.addItem(item)
                }
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // --- swiftui footer ---
        let footerView = FooterView()
        let footerController = NSHostingController(rootView: footerView)
        footerController.view.frame.size = NSSize(width: 300, height: 36)
        
        let footerMenuItem = NSMenuItem()
        footerMenuItem.view = footerController.view
        menu.addItem(footerMenuItem)
    }
}
