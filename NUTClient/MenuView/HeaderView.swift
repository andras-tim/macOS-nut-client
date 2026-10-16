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
    
    var stateTitle: String {
        if state.currentStatus.contains("LB") { return "Battery Low" }
        if state.currentStatus.contains("OB") { return "Running on Battery" }
        return "Running on AC" // default (OL - Online)
    }
    
    var stateColor: Color {
        if state.currentStatus.contains("LB") { return .red }
        if state.currentStatus.contains("OB") { return .orange }
        return .green
    }
    
    var stateIcon: String {
        if state.currentStatus.contains("LB") { return "icon.battery.low" }
        if state.currentStatus.contains("OB") { return "icon.battery.exclamation" }
        return "icon.battery.bolt"
    }

    var body: some View {
        VStack(spacing: 12) {
            // top half: icon, title, ip
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(stateColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(stateIcon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(stateColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(stateTitle)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(state.hostString)
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
                    
                    Text(state.isConnected ? "Connected"
                         : state.localNetworkDenied ? "Local network access needed" : "Disconnected")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(state.isConnected ? .primary : .red)
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
