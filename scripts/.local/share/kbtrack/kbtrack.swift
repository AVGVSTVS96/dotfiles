#!/usr/bin/env swift
import Foundation
import CoreBluetooth

// MARK: - Configuration
let KEYBOARD_ADDRESS = "FC:00:72:C2:AC:AF"
let BATTERY_SERVICE_UUID = CBUUID(string: "180F")
let BATTERY_LEVEL_UUID = CBUUID(string: "2A19")
let START_THRESHOLD = 80
let STOP_THRESHOLD = 5
let TOLERANCE_PERCENT = 5
let CONNECTION_TIMEOUT: TimeInterval = 10.0

let dataDir = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Library/Application Support/kbtrack")
let currentFile = dataDir.appendingPathComponent("current.json")
let sessionsFile = dataDir.appendingPathComponent("sessions.json")
let logFile = dataDir.appendingPathComponent("daemon.log")

// MARK: - Data Models
struct SessionState: Codable {
    var status: String
    var keyboardAddress: String
    var batteryStart: Int
    var batteryPrevious: Int
    var batteryCurrent: Int
    var connected: Bool
    var accumulatedSeconds: Int
    var startedAt: String
}

struct CompletedSession: Codable {
    let sessionNum: Int
    let started: String
    let ended: String
    let stopReason: String
    let batteryStart: Int
    let batteryEnd: Int
    let totalSeconds: Int
    let formatted: String
}

struct SessionsHistory: Codable {
    var sessions: [CompletedSession]
}

// MARK: - Bluetooth Manager
class BluetoothBatteryReader: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var batteryCharacteristic: CBCharacteristic?
    
    private var continuation: CheckedContinuation<(batteryPercent: Int, isConnected: Bool), Error>?
    private var timeoutTask: Task<Void, Never>?
    private let lock = NSLock()
    private var isCompleted: Bool = false
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    private func completeOnce(with result: (batteryPercent: Int, isConnected: Bool)) {
        lock.lock()
        defer { lock.unlock() }
        
        guard !isCompleted, let cont = continuation else {
            return
        }
        
        isCompleted = true
        continuation = nil
        timeoutTask?.cancel()
        timeoutTask = nil
        
        cont.resume(returning: result)
    }
    
    func readBattery() async throws -> (batteryPercent: Int, isConnected: Bool) {
        // Reset completion flag
        isCompleted = false
        
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            // Start timeout
            timeoutTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(CONNECTION_TIMEOUT * 1_000_000_000))
                
                // Check if already completed before trying to complete
                self.lock.lock()
                let shouldComplete = !self.isCompleted
                self.lock.unlock()
                
                if shouldComplete {
                    log("Connection timeout reached")
                    self.completeOnce(with: (batteryPercent: 0, isConnected: false))
                    self.cleanup()
                } else {
                    log("Timeout fired but already completed")
                }
            }
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else {
            log("Bluetooth not powered on: \(central.state.rawValue)")
            completeOnce(with: (batteryPercent: 0, isConnected: false))
            return
        }
        
        // Try to retrieve previously connected peripherals with Battery Service
        let peripherals = centralManager.retrieveConnectedPeripherals(withServices: [BATTERY_SERVICE_UUID])
        
        // Find NuPhy keyboard specifically
        let nuphyPeripheral = peripherals.first { peripheral in
            peripheral.name?.contains("NuPhy") ?? false || peripheral.name?.contains("Air75") ?? false
        }
        
        if let peripheral = nuphyPeripheral {
            log("Found NuPhy keyboard: \(peripheral.name ?? "Unknown")")
            self.peripheral = peripheral
            peripheral.delegate = self
            
            // Check if already connected
            if peripheral.state == .connected {
                peripheral.discoverServices([BATTERY_SERVICE_UUID])
            } else {
                centralManager.connect(peripheral)
            }
        } else {
            log("NuPhy keyboard not connected (found \(peripherals.count) other devices)")
            completeOnce(with: (batteryPercent: 0, isConnected: false))
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log("Connected to peripheral")
        peripheral.discoverServices([BATTERY_SERVICE_UUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log("Failed to connect: \(error?.localizedDescription ?? "unknown")")
        completeOnce(with: (batteryPercent: 0, isConnected: false))
        cleanup()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            log("Error discovering services: \(error)")
            completeOnce(with: (batteryPercent: 0, isConnected: false))
            cleanup()
            return
        }
        
        guard let service = peripheral.services?.first(where: { $0.uuid == BATTERY_SERVICE_UUID }) else {
            log("Battery service not found")
            completeOnce(with: (batteryPercent: 0, isConnected: false))
            cleanup()
            return
        }
        
        peripheral.discoverCharacteristics([BATTERY_LEVEL_UUID], for: service)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            log("Error discovering characteristics: \(error)")
            completeOnce(with: (batteryPercent: 0, isConnected: false))
            cleanup()
            return
        }
        
        guard let characteristic = service.characteristics?.first(where: { $0.uuid == BATTERY_LEVEL_UUID }) else {
            log("Battery characteristic not found")
            completeOnce(with: (batteryPercent: 0, isConnected: false))
            cleanup()
            return
        }
        
        batteryCharacteristic = characteristic
        peripheral.readValue(for: characteristic)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        log("didUpdateValueFor called")
        
        if let error = error {
            log("Error reading value: \(error)")
            completeOnce(with: (batteryPercent: 0, isConnected: false))
            cleanup()
            return
        }
        
        guard let data = characteristic.value, !data.isEmpty else {
            log("No battery data")
            completeOnce(with: (batteryPercent: 0, isConnected: false))
            cleanup()
            return
        }
        
        let batteryLevel = Int(data[0])
        log("Battery level: \(batteryLevel)%")
        
        completeOnce(with: (batteryPercent: batteryLevel, isConnected: true))
        cleanup()
        log("Battery read completed")
    }
    
    private func cleanup() {
        if let peripheral = peripheral, peripheral.state == .connected {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
}

// MARK: - Utility Functions
func log(_ message: String) {
    let timestamp = ISO8601DateFormatter().string(from: Date())
    let logMessage = "[\(timestamp)] \(message)\n"
    
    try? FileManager.default.createDirectory(at: dataDir, withIntermediateDirectories: true)
    
    if let data = logMessage.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: logFile.path) {
            if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } else {
            try? data.write(to: logFile)
        }
    }
}

func formatTime(_ seconds: Int) -> String {
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    return "\(hours)h \(minutes)m"
}

func loadCurrentSession() -> SessionState? {
    guard FileManager.default.fileExists(atPath: currentFile.path),
          let data = try? Data(contentsOf: currentFile),
          let state = try? JSONDecoder().decode(SessionState.self, from: data) else {
        return nil
    }
    return state
}

func saveCurrentSession(_ state: SessionState?) {
    try? FileManager.default.createDirectory(at: dataDir, withIntermediateDirectories: true)
    
    if let state = state {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(state) {
            try? data.write(to: currentFile)
        }
    } else {
        try? FileManager.default.removeItem(at: currentFile)
    }
}

func saveCompletedSession(state: SessionState, stopReason: String) {
    let history = loadHistory()
    let sessionNum = history.sessions.count + 1
    
    let session = CompletedSession(
        sessionNum: sessionNum,
        started: state.startedAt,
        ended: ISO8601DateFormatter().string(from: Date()),
        stopReason: stopReason,
        batteryStart: state.batteryStart,
        batteryEnd: state.batteryCurrent,
        totalSeconds: state.accumulatedSeconds,
        formatted: formatTime(state.accumulatedSeconds)
    )
    
    var newHistory = history
    newHistory.sessions.append(session)
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    if let data = try? encoder.encode(newHistory) {
        try? data.write(to: sessionsFile)
    }
}

func loadHistory() -> SessionsHistory {
    guard FileManager.default.fileExists(atPath: sessionsFile.path),
          let data = try? Data(contentsOf: sessionsFile),
          let history = try? JSONDecoder().decode(SessionsHistory.self, from: data) else {
        return SessionsHistory(sessions: [])
    }
    return history
}

// MARK: - Daemon Logic
func runDaemon() async {
    log("=== Daemon cycle started ===")
    
    let reader = BluetoothBatteryReader()
    let result = try? await reader.readBattery()
    
    let batteryPercent = result?.batteryPercent ?? 0
    let isConnected = result?.isConnected ?? false
    
    log("Read result - Battery: \(batteryPercent)%, Connected: \(isConnected)")
    
    var currentState = loadCurrentSession()
    
    // No active session - check if we should start
    if currentState == nil {
        if isConnected && batteryPercent >= START_THRESHOLD {
            log("Starting new session at \(batteryPercent)%")
            currentState = SessionState(
                status: "tracking",
                keyboardAddress: KEYBOARD_ADDRESS,
                batteryStart: batteryPercent,
                batteryPrevious: batteryPercent,
                batteryCurrent: batteryPercent,
                connected: isConnected,
                accumulatedSeconds: 0,
                startedAt: ISO8601DateFormatter().string(from: Date())
            )
            saveCurrentSession(currentState)
        } else {
            log("No session active, conditions not met (battery: \(batteryPercent)%, connected: \(isConnected))")
        }
        return
    }
    
    // Active session exists
    guard var state = currentState else { return }
    
    state.batteryCurrent = batteryPercent
    state.connected = isConnected
    
    // Check stop conditions
    if batteryPercent < STOP_THRESHOLD {
        log("Battery depleted (\(batteryPercent)%), stopping session")
        saveCompletedSession(state: state, stopReason: "battery_depleted")
        saveCurrentSession(nil)
        return
    }
    
    if batteryPercent > state.batteryPrevious {
        log("Charging detected (\(state.batteryPrevious)% -> \(batteryPercent)%), stopping session")
        saveCompletedSession(state: state, stopReason: "charging_detected")
        saveCurrentSession(nil)
        return
    }
    
    // Check 5% tolerance rule
    let batteryDiff = abs(batteryPercent - state.batteryPrevious)
    if isConnected && batteryDiff > TOLERANCE_PERCENT && batteryPercent > state.batteryPrevious {
        log("Battery jumped \(batteryDiff)% (\(state.batteryPrevious)% -> \(batteryPercent)%), likely charging")
        saveCompletedSession(state: state, stopReason: "charging_detected")
        saveCurrentSession(nil)
        return
    }
    
    // Accumulate time only if connected
    if isConnected {
        state.accumulatedSeconds += 60
        state.batteryPrevious = batteryPercent
        log("Accumulated time: \(formatTime(state.accumulatedSeconds))")
    } else {
        log("Keyboard disconnected, pausing timer")
    }
    
    saveCurrentSession(state)
    log("=== Daemon cycle completed ===")
}

// MARK: - CLI Commands
func showStatus() {
    guard let state = loadCurrentSession() else {
        print("No active tracking session")
        return
    }
    
    let connectedSymbol = state.connected ? "✓" : "✗"
    let batteryUsed = state.batteryStart - state.batteryCurrent
    let hours = Double(state.accumulatedSeconds) / 3600.0
    
    print(String(repeating: "=", count: 60))
    print("NuPhy Air75 V3-1: \(state.connected ? "Connected" : "Disconnected") \(connectedSymbol)")
    print(String(repeating: "=", count: 60))
    
    // Current status
    print("\n📊 Current Status:")
    print("  Battery: \(state.batteryCurrent)% (started at \(state.batteryStart)%)")
    print("  Used: \(batteryUsed)%")
    print("  Connected time: \(formatTime(state.accumulatedSeconds))")
    print("  Started: \(state.startedAt)")
    
    // Calculate estimates if we have meaningful data
    if batteryUsed > 0 && hours > 0.1 {
        let hoursPerPercent = hours / Double(batteryUsed)
        let dischargeRate = Double(batteryUsed) / hours
        
        // Estimated remaining time (current% - 5% stop threshold)
        let remainingPercent = state.batteryCurrent - STOP_THRESHOLD
        let estimatedRemainingHours = Double(remainingPercent) * hoursPerPercent
        
        // Estimated total battery life (from start% to 5%)
        let totalUsablePercent = state.batteryStart - STOP_THRESHOLD
        let estimatedTotalHours = Double(totalUsablePercent) * hoursPerPercent
        
        print("\n⚡️ Discharge Rate:")
        print("  \(String(format: "%.2f", dischargeRate))% per hour")
        print("  \(String(format: "%.1f", hoursPerPercent)) hours per 1%")
        
        print("\n🔋 Estimates:")
        print("  Remaining: ~\(formatTime(Int(estimatedRemainingHours * 3600))) (\(state.batteryCurrent)% → 5%)")
        print("  Total life: ~\(formatTime(Int(estimatedTotalHours * 3600))) (\(state.batteryStart)% → 5%)")
        
        // Days estimate if > 24 hours
        if estimatedTotalHours >= 24 {
            let days = estimatedTotalHours / 24.0
            print("  (~\(String(format: "%.1f", days)) days)")
        }
    } else {
        print("\n⏳ Gathering data... (estimates available after some battery usage)")
    }
    
    print("")
}

func showHistory() {
    let history = loadHistory()
    
    if history.sessions.isEmpty {
        print("No completed sessions yet")
        return
    }
    
    print("Completed Battery Cycles:")
    print(String(repeating: "=", count: 60))
    for session in history.sessions.reversed() {
        let startDate = session.started.prefix(10)
        let endDate = session.ended.prefix(10)
        let percentUsed = session.batteryStart - session.batteryEnd
        print("Session \(session.sessionNum): \(startDate) → \(endDate)")
        print("  Time: \(session.formatted)")
        print("  Battery: \(session.batteryStart)% → \(session.batteryEnd)% (\(percentUsed)% used)")
        print("  Reason: \(session.stopReason)")
        print("")
    }
}

func resetSession() {
    if let state = loadCurrentSession() {
        saveCompletedSession(state: state, stopReason: "manual_reset")
        saveCurrentSession(nil)
        print("Session reset and saved to history")
    } else {
        print("No active session to reset")
    }
}

// MARK: - Main
func main() async {
    let args = CommandLine.arguments
    
    if args.count < 2 {
        print("Usage: kbtrack <command>")
        print("Commands:")
        print("  daemon   - Run monitoring cycle (called by LaunchAgent)")
        print("  status   - Show current tracking status")
        print("  history  - Show completed sessions")
        print("  reset    - Force stop current session")
        exit(1)
    }
    
    switch args[1] {
    case "daemon":
        await runDaemon()
    case "status":
        showStatus()
    case "history":
        showHistory()
    case "reset":
        resetSession()
    default:
        print("Unknown command: \(args[1])")
        exit(1)
    }
}

// Run main
Task {
    await main()
    exit(0)
}

RunLoop.main.run()
