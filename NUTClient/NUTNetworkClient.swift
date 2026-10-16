//
//  NUTNetworkClient.swift
//  NUTClient
//
//  Created by Barna Fulop on 18.05.2026.
//
import Foundation
import Network

class NUTClient {
    let state: UPSStateMachine
    
    private var connection: NWConnection?
    private var host: NWEndpoint.Host
    private var port: NWEndpoint.Port
    private var upsName: String
    private var username: String?
    private var password: String?
    
    private var streamBuffer: String = ""
    private var pollTimer: Timer?
    private var isReconnecting: Bool = false
    private var userRequestedDisconnect: Bool = false
    
    init(state: UPSStateMachine, host: String, port: UInt16 = 3493,
         upsName: String = "ups", username: String? = nil, password: String? = nil) {
        self.state = state
        self.state.hostString = host
        
        self.host = NWEndpoint.Host(host)
        self.port = NWEndpoint.Port(rawValue: port) ?? 3493
        self.upsName = upsName
        self.username = username
        self.password = password
    }
    
    // MARK: - Dynamic Configuration
    
    func applySettingsAndConnect(host: String, port: String, upsName: String, username: String, password: String) {
        self.state.hostString = host
        self.host = NWEndpoint.Host(host)
        self.port = NWEndpoint.Port(rawValue: UInt16(port) ?? 3493) ?? 3493
        let trimmedName = upsName.trimmingCharacters(in: .whitespaces)
        self.upsName = trimmedName.isEmpty ? "ups" : trimmedName
        
        // Only assign credentials if they aren't empty
        self.username = username.trimmingCharacters(in: .whitespaces).isEmpty ? nil : username
        self.password = password.isEmpty ? nil : password
        
        self.connect()
    }
    
    func disconnect() {
        userRequestedDisconnect = true
        isReconnecting = false
        
        pollTimer?.invalidate()
        pollTimer = nil
        
        if connection != nil {
            connection?.stateUpdateHandler = nil
            connection?.cancel()
            connection = nil
        }
        
        DispatchQueue.main.async {
            self.state.isConnected = false
            self.state.variables.removeAll() // Clear old data from the UI
        }
    }
    
    func connect() {
        userRequestedDisconnect = false // Reset the manual disconnect flag

        if connection != nil {
            connection?.cancel()
            connection = nil
        }
        
        let tcpOptions = NWProtocolTCP.Options()
        let parameters = NWParameters(tls: nil, tcp: tcpOptions)
        connection = NWConnection(host: host, port: port, using: parameters)
        
        connection?.stateUpdateHandler = { [weak self] networkState in
            DispatchQueue.main.async {
                switch networkState {
                case .ready:
                    self?.state.localNetworkDenied = false
                    self?.state.connectionError = nil
                    self?.state.isConnected = true
                    self?.startReceiving()
                    self?.performHandshake()
                case .waiting(let error):
                    // The connection keeps waiting and goes ready by itself once access is granted.
                    if self?.connection?.currentPath?.unsatisfiedReason == .localNetworkDenied {
                        self?.state.localNetworkDenied = true
                    }
                    self?.state.connectionError = error.localizedDescription
                case .failed(let error):
                    self?.state.connectionError = error.localizedDescription
                    print("Connection failed: \(error)")
                    self?.handleDisconnect()
                case .cancelled:
                    self?.handleDisconnect()
                default: break
                }
            }
        }
        connection?.start(queue: .global())
    }
    
    private func handleDisconnect() {
        guard !userRequestedDisconnect else { return }
        guard !isReconnecting else { return }
        isReconnecting = true
        
        DispatchQueue.main.async {
            self.state.isConnected = false
        }
        
        pollTimer?.invalidate()
        pollTimer = nil
        
        if connection != nil {
            connection?.stateUpdateHandler = nil
            connection?.cancel()
            connection = nil
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self else { return }
            self.isReconnecting = false
            self.connect()
        }
    }
    
    private func startReceiving() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, _, isComplete, error in
            if let data = content, let textChunk = String(data: data, encoding: .utf8) {
                self?.processIncomingText(textChunk)
            }
            
            if let error = error {
                print("Receive error: \(error)")
                DispatchQueue.main.async { self?.handleDisconnect() }
                return
            }
            
            if !isComplete {
                self?.startReceiving()
            } else {
                DispatchQueue.main.async { self?.handleDisconnect() }
            }
        }
    }
    
    private func performHandshake() {
        if let user = username, let pass = password {
            send(command: "USERNAME \(user)\nPASSWORD \(pass)\n")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.startPolling() }
        } else {
            startPolling()
        }
    }
    
    private func startPolling() {
        fetchStats()
        DispatchQueue.main.async {
            self.pollTimer?.invalidate()
            // .common modes: keep polling while the menu is open; upsd drops a client silent for 60 s.
            let timer = Timer(timeInterval: 5.0, repeats: true) { [weak self] _ in
                self?.fetchStats()
            }
            RunLoop.main.add(timer, forMode: .common)
            self.pollTimer = timer
        }
    }
    
    private func fetchStats() {
        send(command: "LIST VAR \(upsName)\n")
    }
    
    private func send(command: String) {
        guard state.isConnected, let currentConnection = connection, let data = command.data(using: .utf8) else { return }
        currentConnection.send(content: data, completion: .contentProcessed({ error in
            if let error = error {
                print("Send error: \(error)")
                DispatchQueue.main.async { [weak self] in self?.handleDisconnect() }
            }
        }))
    }
    
    private func processIncomingText(_ text: String) {
        streamBuffer += text
        var lines = streamBuffer.components(separatedBy: .newlines)
        streamBuffer = lines.removeLast()
        
        var parsedDict: [String: String] = [:]
        
        for line in lines {
            // e.g. "ERR UNKNOWN-UPS" for a wrong UPS name: the socket is fine, the answer is not
            if line.hasPrefix("ERR ") {
                let reason = "server replied " + line
                DispatchQueue.main.async { self.state.connectionError = reason }
            }
            if line.hasPrefix("VAR ") {
                let parts = line.split(separator: "\"", maxSplits: 2, omittingEmptySubsequences: false)
                if parts.count >= 2 {
                    let prefixParts = parts[0].trimmingCharacters(in: .whitespaces).components(separatedBy: " ")
                    if prefixParts.count >= 3 {
                        let varName = String(prefixParts[2])
                        let varValue = String(parts[1])
                        parsedDict[varName] = varValue // Map into dictionary
                    }
                }
            }
        }
        
        if !parsedDict.isEmpty {
            DispatchQueue.main.async {
                self.state.connectionError = nil
                self.state.variables.merge(parsedDict) { (_, new) in new }
            }
        }
    }
}
