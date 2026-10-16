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
        // as tall as its content: a disconnect reason can take several lines
        let headerHeight = headerController.sizeThatFits(in: NSSize(width: 300, height: 1000)).height
        headerController.view.frame.size = NSSize(width: 300, height: max(headerHeight, 155))
        
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
                
                // Views, not plain items: macOS dims disabled menu items whatever their colour, and a view row
                // is neither dimmed nor highlighted on hover.
                menu.addItem(hostedItem(MenuSectionTitleView(title: section.title), height: 22))
                for row in section.items {
                    menu.addItem(hostedItem(MenuValueRowView(label: row.label, value: row.value), height: 22))
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

private func hostedItem<V: View>(_ view: V, height: CGFloat) -> NSMenuItem {
    let controller = NSHostingController(rootView: view)
    controller.view.frame.size = NSSize(width: 300, height: height)
    let item = NSMenuItem()
    item.view = controller.view
    return item
}

/// A section title in the menu body, styled like the header's secondary text.
struct MenuSectionTitleView: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 14)
    }
}

/// One selected UPS value: label left, value right, like the header's stat lines.
struct MenuValueRowView: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 14)
    }
}
