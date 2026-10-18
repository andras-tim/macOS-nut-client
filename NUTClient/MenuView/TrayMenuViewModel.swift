//
//  TrayMenuViewModel.swift
//  NUTClient
//
//  Created by Barna Fulop on 20.05.2026.
//
import Foundation

struct MenuSection {
    let title: String
    let items: [MenuRow]
}

struct MenuRow {
    let id: String
    let displayTitle: String
    let label: String
    let value: String
}

class TrayMenuViewModel {
    let state: UPSStateMachine
    
    init(state: UPSStateMachine) {
        self.state = state
    }
    
    func buildMenuData() -> [MenuSection] {
        let savedVars = UserDefaults.standard.stringArray(forKey: "SelectedUPSVars") ?? []
        guard !savedVars.isEmpty else { return [] }
        
        let selectedEnums = savedVars.compactMap { UPSVariable(rawValue: $0) }
        var sections: [MenuSection] = []
        
        for category in UPSCategory.allCases {
            let varsInCategory = selectedEnums.filter { $0.category == category }
            
            if !varsInCategory.isEmpty {
                var rows: [MenuRow] = []
                
                for variable in varsInCategory {
                    if let liveValue = state.variables[variable.rawValue] {
                        let formattedValue = variable.formatLiveValue(liveValue)
                        let title = "\(variable.displayName): \(formattedValue)"
                        rows.append(MenuRow(id: variable.rawValue, displayTitle: title,
                                            label: variable.displayName, value: formattedValue))
                    }
                }
                
                // only add the section if it actually has live data
                if !rows.isEmpty {
                    sections.append(MenuSection(title: category.title.uppercased(), items: rows))
                }
            }
        }
        
        return sections
    }
}
