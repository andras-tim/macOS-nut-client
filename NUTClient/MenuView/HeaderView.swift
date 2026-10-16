//
//  HeaderView.swift
//  NUTstate
//
//  Created by Barna Fulop on 19.05.2026.
//
import SwiftUI
import Combine

struct HeaderView: View {
    @ObservedObject var state: UPSStateMachine
    
    var stateColor: Color {
        switch state.powerState {
        case .charging: return .blue
        case .charged: return .green
        case .discharging: return .yellow
        case .critical: return .red
        case .disconnected: return .gray
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // top half: icon, title, ip
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(stateColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    // the menu bar icon, bigger and coloured
                    HStack(spacing: 1) {
                        Image(systemName: state.iconSymbolName)
                        if state.powerState == .disconnected {
                            Image(systemName: "questionmark")
                                .font(.system(size: 13, weight: .bold))
                        }
                    }
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(stateColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.stateTitle)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(state.upsTitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            Divider()
                        
            // bottom half: stats list
            VStack(spacing: 8) {
                // connection status
                HStack {
                    Image("icon.globe")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    Text("NUT Status")
                        .foregroundColor(.secondary)
                        .font(.system(size: 13))
                    
                    Spacer()
                    
                    Text(state.powerState == .disconnected
                         ? (state.localNetworkDenied ? "Local Network access needed" : (state.connectionError ?? "Not connected"))
                         : "Connected")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(state.powerState == .disconnected ? .red : .primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                }
                
                // battery charge level
                HStack {
                    Image("icon.batteryblock")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    Text("Battery Level")
                        .foregroundColor(.secondary)
                        .font(.system(size: 13))
                    
                    Spacer()
                    
                    Text("\(state.batteryCharge)%")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                // current load
                HStack {
                    Image("icon.bolt.square")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    Text("Current Load")
                        .foregroundColor(.secondary)
                        .font(.system(size: 13))
                    
                    Spacer()
                    
                    Text("\(state.loadPercentage)%")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(14)
        .frame(width: 300)
    }
}
