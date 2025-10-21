#!/usr/bin/env swift
import Foundation
import CoreBluetooth

// MARK: - Shared formatters
let isoFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

// MARK: - Paths
let dataDir = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Library/Application Support/kbtrack")
let currentFile = dataDir.appendingPathComponent("current.json")
let sessionsFile = dataDir.appendingPathComponent("sessions.json")
let logFile = dataDir.appendingPathComponent("daemon.log")
let samplesFile = dataDir.appendingPathComponent("samples.jsonl")

// MARK: - Lock helpers
extension NSLock {
    @discardableResult
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}

// MARK: - Configuration
struct TrackerConfig {
    let keyboardAddress: String
    let keyboardNameHints: [String]
    let startThreshold: Int
    let stopThreshold: Int
    let tolerancePercent: Int
    let connectionTimeout: TimeInterval
    let failureGraceCycles: Int
    let smoothingWindow: Int
    let samplesRetention: Int
    let verboseSampleCount: Int

    static func loadFromEnvironment() -> TrackerConfig {
        let env = ProcessInfo.processInfo.environment
        let address = env["KBTRACK_KEYBOARD_ADDRESS"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "FC:00:72:C2:AC:AF"
        let hintsRaw = env["KBTRACK_KEYBOARD_HINTS"] ?? "NuPhy,Air75"
        let hints = hintsRaw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return TrackerConfig(
            keyboardAddress: address,
            keyboardNameHints: hints.isEmpty ? ["NuPhy", "Air75"] : hints,
            startThreshold: envInt(env, name: "KBTRACK_START_THRESHOLD", defaultValue: 80),
            stopThreshold: envInt(env, name: "KBTRACK_STOP_THRESHOLD", defaultValue: 5),
            tolerancePercent: envInt(env, name: "KBTRACK_TOLERANCE_PERCENT", defaultValue: 5),
            connectionTimeout: envDouble(env, name: "KBTRACK_CONNECTION_TIMEOUT", defaultValue: 10.0),
            failureGraceCycles: envInt(env, name: "KBTRACK_FAILURE_GRACE_CYCLES", defaultValue: 10),
            smoothingWindow: envInt(env, name: "KBTRACK_SMOOTHING_WINDOW", defaultValue: 120),
            samplesRetention: envInt(env, name: "KBTRACK_SAMPLES_RETENTION", defaultValue: 5000),
            verboseSampleCount: envInt(env, name: "KBTRACK_VERBOSE_SAMPLE_COUNT", defaultValue: 10)
        )
    }

    func overriding(_ overrides: ConfigOverrides) -> TrackerConfig {
        TrackerConfig(
            keyboardAddress: keyboardAddress,
            keyboardNameHints: keyboardNameHints,
            startThreshold: overrides.startThreshold ?? startThreshold,
            stopThreshold: overrides.stopThreshold ?? stopThreshold,
            tolerancePercent: overrides.tolerancePercent ?? tolerancePercent,
            connectionTimeout: overrides.connectionTimeout ?? connectionTimeout,
            failureGraceCycles: overrides.failureGraceCycles ?? failureGraceCycles,
            smoothingWindow: overrides.smoothingWindow ?? smoothingWindow,
            samplesRetention: overrides.samplesRetention ?? samplesRetention,
            verboseSampleCount: overrides.verboseSampleCount ?? verboseSampleCount
        )
    }
}

struct ConfigOverrides {
    var startThreshold: Int?
    var stopThreshold: Int?
    var tolerancePercent: Int?
    var connectionTimeout: TimeInterval?
    var failureGraceCycles: Int?
    var smoothingWindow: Int?
    var samplesRetention: Int?
    var verboseSampleCount: Int?
}

private func envInt(_ env: [String: String], name: String, defaultValue: Int) -> Int {
    guard let raw = env[name]?.trimmingCharacters(in: .whitespacesAndNewlines), let value = Int(raw) else {
        return defaultValue
    }
    return value
}

private func envDouble(_ env: [String: String], name: String, defaultValue: TimeInterval) -> TimeInterval {
    guard let raw = env[name]?.trimmingCharacters(in: .whitespacesAndNewlines), let value = Double(raw) else {
        return defaultValue
    }
    return value
}

let baseConfig = TrackerConfig.loadFromEnvironment()

// MARK: - Bluetooth UUIDs
let batteryServiceUUID = CBUUID(string: "180F")
let batteryLevelUUID = CBUUID(string: "2A19")

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
    var consecutiveFailures: Int
    var lastSampleAt: String?
    var lastValidSampleAt: String?

    enum CodingKeys: String, CodingKey {
        case status
        case keyboardAddress
        case batteryStart
        case batteryPrevious
        case batteryCurrent
        case connected
        case accumulatedSeconds
        case startedAt
        case consecutiveFailures
        case lastSampleAt
        case lastValidSampleAt
    }

    init(status: String, keyboardAddress: String, batteryStart: Int, batteryPrevious: Int, batteryCurrent: Int, connected: Bool, accumulatedSeconds: Int, startedAt: String, consecutiveFailures: Int = 0, lastSampleAt: String? = nil, lastValidSampleAt: String? = nil) {
        self.status = status
        self.keyboardAddress = keyboardAddress
        self.batteryStart = batteryStart
        self.batteryPrevious = batteryPrevious
        self.batteryCurrent = batteryCurrent
        self.connected = connected
        self.accumulatedSeconds = accumulatedSeconds
        self.startedAt = startedAt
        self.consecutiveFailures = consecutiveFailures
        self.lastSampleAt = lastSampleAt
        self.lastValidSampleAt = lastValidSampleAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(String.self, forKey: .status)
        keyboardAddress = try container.decodeIfPresent(String.self, forKey: .keyboardAddress) ?? ""
        batteryStart = try container.decode(Int.self, forKey: .batteryStart)
        batteryPrevious = try container.decode(Int.self, forKey: .batteryPrevious)
        batteryCurrent = try container.decode(Int.self, forKey: .batteryCurrent)
        connected = try container.decode(Bool.self, forKey: .connected)
        accumulatedSeconds = try container.decode(Int.self, forKey: .accumulatedSeconds)
        startedAt = try container.decode(String.self, forKey: .startedAt)
        consecutiveFailures = try container.decodeIfPresent(Int.self, forKey: .consecutiveFailures) ?? 0
        lastSampleAt = try container.decodeIfPresent(String.self, forKey: .lastSampleAt)
        lastValidSampleAt = try container.decodeIfPresent(String.self, forKey: .lastValidSampleAt)
    }
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

struct Sample: Codable {
    let timestamp: String
    let battery: Int
    let connected: Bool
    let valid: Bool
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

    private let connectionTimeout: TimeInterval
    private let nameHints: [String]

    init(connectionTimeout: TimeInterval, nameHints: [String]) {
        self.connectionTimeout = connectionTimeout
        self.nameHints = nameHints
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    private func completeOnce(with result: (batteryPercent: Int, isConnected: Bool)) {
        guard let cont = lock.withLock({ () -> CheckedContinuation<(batteryPercent: Int, isConnected: Bool), Error>? in
            guard !isCompleted, let cont = continuation else {
                return nil
            }
            isCompleted = true
            continuation = nil
            timeoutTask?.cancel()
            timeoutTask = nil
            return cont
        }) else {
            return
        }

        cont.resume(returning: result)
    }

    func readBattery() async throws -> (batteryPercent: Int, isConnected: Bool) {
        isCompleted = false

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            timeoutTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(self.connectionTimeout * 1_000_000_000))

                let shouldComplete = self.lock.withLock { !self.isCompleted }

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
        let peripherals = centralManager.retrieveConnectedPeripherals(withServices: [batteryServiceUUID])

        let nuphyPeripheral = peripherals.first { peripheral in
            guard let name = peripheral.name?.lowercased() else { return false }
            return nameHints.contains { hint in name.contains(hint.lowercased()) }
        }
        
        if let peripheral = nuphyPeripheral {
            log("Found NuPhy keyboard: \(peripheral.name ?? "Unknown")")
            self.peripheral = peripheral
            peripheral.delegate = self
            
            // Check if already connected
            if peripheral.state == .connected {
                peripheral.discoverServices([batteryServiceUUID])
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
        peripheral.discoverServices([batteryServiceUUID])
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
        
        guard let service = peripheral.services?.first(where: { $0.uuid == batteryServiceUUID }) else {
            log("Battery service not found")
            completeOnce(with: (batteryPercent: 0, isConnected: false))
            cleanup()
            return
        }
        
        peripheral.discoverCharacteristics([batteryLevelUUID], for: service)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            log("Error discovering characteristics: \(error)")
            completeOnce(with: (batteryPercent: 0, isConnected: false))
            cleanup()
            return
        }
        
        guard let characteristic = service.characteristics?.first(where: { $0.uuid == batteryLevelUUID }) else {
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
    let timestamp = isoFormatter.string(from: Date())
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
        ended: isoFormatter.string(from: Date()),
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

func appendSample(_ sample: Sample, retentionLimit: Int) {
    try? FileManager.default.createDirectory(at: dataDir, withIntermediateDirectories: true)
    let encoder = JSONEncoder()
    guard let encoded = try? encoder.encode(sample), var line = String(data: encoded, encoding: .utf8) else {
        return
    }
    line.append("\n")

    if FileManager.default.fileExists(atPath: samplesFile.path) {
        if let handle = try? FileHandle(forWritingTo: samplesFile) {
            handle.seekToEndOfFile()
            if let data = line.data(using: .utf8) {
                handle.write(data)
            }
            handle.closeFile()
        }
    } else {
        try? line.write(to: samplesFile, atomically: true, encoding: .utf8)
    }

    pruneSamplesIfNeeded(limit: retentionLimit)
}

func pruneSamplesIfNeeded(limit: Int) {
    guard limit > 0,
          let raw = try? String(contentsOf: samplesFile, encoding: .utf8) else {
        return
    }

    var lines = raw.split(whereSeparator: { $0.isNewline }).map(String.init)
    if lines.count <= limit {
        return
    }

    lines = Array(lines.suffix(limit))
    let trimmed = lines.joined(separator: "\n") + "\n"
    try? trimmed.write(to: samplesFile, atomically: true, encoding: .utf8)
}

func loadRecentSamples(limit: Int) -> [Sample] {
    guard limit > 0,
          let raw = try? String(contentsOf: samplesFile, encoding: .utf8) else {
        return []
    }

    let lines = raw.split(whereSeparator: { $0.isNewline })
    let slice = lines.suffix(limit)
    let decoder = JSONDecoder()
    var samples: [Sample] = []
    for entry in slice {
        if let data = entry.data(using: .utf8), let sample = try? decoder.decode(Sample.self, from: data) {
            samples.append(sample)
        }
    }
    return samples
}

func computeSmoothedRate(samples: [Sample]) -> (rate: Double, hoursPerPercent: Double, start: Sample, end: Sample)? {
    let connectedSamples = samples.filter { $0.valid && $0.connected }
    guard connectedSamples.count >= 2,
          let first = connectedSamples.first,
          let last = connectedSamples.last,
          let startDate = isoFormatter.date(from: first.timestamp),
          let endDate = isoFormatter.date(from: last.timestamp),
          endDate > startDate else {
        return nil
    }

    let percentDrop = first.battery - last.battery
    guard percentDrop > 0 else {
        return nil
    }

    let seconds = endDate.timeIntervalSince(startDate)
    guard seconds > 0 else {
        return nil
    }

    let hours = seconds / 3600.0
    let rate = Double(percentDrop) / hours
    let hoursPerPercent = hours / Double(percentDrop)
    return (rate, hoursPerPercent, first, last)
}

func pendingStopDescription(state: SessionState, config: TrackerConfig) -> String {
    if state.batteryCurrent <= config.stopThreshold {
        return "Battery at \(state.batteryCurrent)% (≤ \(config.stopThreshold)% threshold)"
    }

    if state.consecutiveFailures > 0 {
        let remaining = max(0, config.failureGraceCycles - state.consecutiveFailures)
        if remaining == 0 {
            return "Grace exhausted: will stop if next read fails"
        }
        return "Awaiting reconnect: \(state.consecutiveFailures) failure cycle(s); stops after \(remaining) more"
    }

    return "None"
}

// MARK: - Daemon Logic
func runDaemon(config: TrackerConfig) async {
    log("=== Daemon cycle started ===")

    let reader = BluetoothBatteryReader(connectionTimeout: config.connectionTimeout, nameHints: config.keyboardNameHints)
    let result = try? await reader.readBattery()

    let now = Date()
    let timestamp = isoFormatter.string(from: now)
    let batteryPercent = result?.batteryPercent ?? 0
    let isConnected = result?.isConnected ?? false
    let validSample = isConnected && batteryPercent > 0

    appendSample(
        Sample(timestamp: timestamp, battery: batteryPercent, connected: isConnected, valid: validSample),
        retentionLimit: config.samplesRetention
    )

    log("Read result - Battery: \(batteryPercent)%, Connected: \(isConnected)")

    var currentState = loadCurrentSession()

    if currentState == nil {
        if validSample && batteryPercent >= config.startThreshold {
            log("Starting new session at \(batteryPercent)%")
            currentState = SessionState(
                status: "tracking",
                keyboardAddress: config.keyboardAddress,
                batteryStart: batteryPercent,
                batteryPrevious: batteryPercent,
                batteryCurrent: batteryPercent,
                connected: isConnected,
                accumulatedSeconds: 0,
                startedAt: timestamp,
                consecutiveFailures: 0,
                lastSampleAt: timestamp,
                lastValidSampleAt: timestamp
            )
            saveCurrentSession(currentState)
        } else {
            log("No session active, conditions not met (battery: \(batteryPercent)%, connected: \(isConnected))")
        }
        return
    }

    guard var state = currentState else {
        return
    }

    state.lastSampleAt = timestamp

    if !validSample {
        state.connected = false
        state.consecutiveFailures += 1
        log("Transient failure detected (cycle \(state.consecutiveFailures)/\(config.failureGraceCycles))")

        if state.consecutiveFailures >= config.failureGraceCycles {
            let stopReason = state.batteryCurrent <= config.stopThreshold ? "battery_depleted" : "signal_lost"
            log("Grace limit reached, stopping session with reason \(stopReason)")
            saveCompletedSession(state: state, stopReason: stopReason)
            saveCurrentSession(nil)
        } else {
            saveCurrentSession(state)
        }
        return
    }

    state.connected = true
    state.consecutiveFailures = 0
    state.lastValidSampleAt = timestamp

    let previousPercent = state.batteryPrevious
    state.batteryCurrent = batteryPercent

    if batteryPercent < config.stopThreshold {
        log("Battery depleted (\(batteryPercent)%), stopping session")
        saveCompletedSession(state: state, stopReason: "battery_depleted")
        saveCurrentSession(nil)
        return
    }

    if batteryPercent > previousPercent {
        log("Charging detected (\(previousPercent)% -> \(batteryPercent)%), stopping session")
        saveCompletedSession(state: state, stopReason: "charging_detected")
        saveCurrentSession(nil)
        return
    }

    let batteryDiff = abs(batteryPercent - previousPercent)
    if batteryPercent > previousPercent && batteryDiff > config.tolerancePercent {
        log("Battery jumped \(batteryDiff)% (\(previousPercent)% -> \(batteryPercent)%), likely charging")
        saveCompletedSession(state: state, stopReason: "charging_detected")
        saveCurrentSession(nil)
        return
    }

    state.accumulatedSeconds += 60
    state.batteryPrevious = batteryPercent
    log("Accumulated time: \(formatTime(state.accumulatedSeconds))")

    saveCurrentSession(state)
    log("=== Daemon cycle completed ===")
}

// MARK: - CLI Commands
func showStatus(config: TrackerConfig, verbose: Bool) {
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

        let remainingPercent = max(0, state.batteryCurrent - config.stopThreshold)
        let estimatedRemainingHours = Double(remainingPercent) * hoursPerPercent

        let totalUsablePercent = max(0, state.batteryStart - config.stopThreshold)
        let estimatedTotalHours = Double(totalUsablePercent) * hoursPerPercent
        
        print("\n⚡️ Discharge Rate:")
        print("  \(String(format: "%.2f", dischargeRate))% per hour")
        print("  \(String(format: "%.1f", hoursPerPercent)) hours per 1%")
        
        print("\n🔋 Estimates:")
        print("  Remaining: ~\(formatTime(Int(estimatedRemainingHours * 3600))) (\(state.batteryCurrent)% → \(config.stopThreshold)%)")
        print("  Total life: ~\(formatTime(Int(estimatedTotalHours * 3600))) (\(state.batteryStart)% → \(config.stopThreshold)%)")
        
        // Days estimate if > 24 hours
        if estimatedTotalHours >= 24 {
            let days = estimatedTotalHours / 24.0
            print("  (~\(String(format: "%.1f", days)) days)")
        }
    } else {
        print("\n⏳ Gathering data... (estimates available after some battery usage)")
    }
    
    let samples = loadRecentSamples(limit: config.smoothingWindow)
    if let smoothed = computeSmoothedRate(samples: samples) {
        print("\n🎯 Smoothed rate (last \(samples.count) samples):")
        print("  \(String(format: "%.2f", smoothed.rate))% per hour")
        print("  \(String(format: "%.1f", smoothed.hoursPerPercent)) hours per 1%")
    }

    let pending = pendingStopDescription(state: state, config: config)
    print("\n🚦 Pending stop condition: \(pending)")

    if verbose {
        print("\n🔍 Verbose details:")
        print("  Failure grace: \(state.consecutiveFailures)/\(config.failureGraceCycles)")
        if let lastSampleAt = state.lastSampleAt {
            print("  Last sample: \(lastSampleAt)")
        }
        if let lastValidSampleAt = state.lastValidSampleAt {
            print("  Last valid sample: \(lastValidSampleAt)")
        }
        print("  Thresholds: start ≥ \(config.startThreshold)% | stop < \(config.stopThreshold)% | charge jump > \(config.tolerancePercent)%")

        let recent = samples.suffix(config.verboseSampleCount)
        if !recent.isEmpty {
            print("\n  Recent samples (oldest → newest):")
            for sample in recent {
                let validity = sample.valid ? "valid" : "invalid"
                let link = sample.connected ? "connected" : "disconnected"
                print("    • \(sample.timestamp) — \(sample.battery)% (\(link), \(validity))")
            }
        }
    }

    print("")
}

func parseArguments(args: [String]) -> (command: String, overrides: ConfigOverrides, flags: Set<String>) {
    var overrides = ConfigOverrides()
    var flags = Set<String>()

    guard args.count >= 2 else {
        return (command: "", overrides: overrides, flags: flags)
    }

    let command = args[1]

    let optionArgs = args.dropFirst(2)
    for option in optionArgs {
        if option == "--verbose" {
            flags.insert("verbose")
            continue
        }

        let parts = option.split(separator: "=", maxSplits: 1).map(String.init)
        guard parts.count == 2 else {
            print("Ignoring malformed option: \(option)")
            continue
        }

        let key = parts[0]
        let value = parts[1]

        switch key {
        case "--start-threshold":
            overrides.startThreshold = Int(value)
        case "--stop-threshold":
            overrides.stopThreshold = Int(value)
        case "--tolerance":
            overrides.tolerancePercent = Int(value)
        case "--timeout":
            overrides.connectionTimeout = TimeInterval(value)
        case "--grace-cycles":
            overrides.failureGraceCycles = Int(value)
        case "--smooth-window":
            overrides.smoothingWindow = Int(value)
        case "--samples-retention":
            overrides.samplesRetention = Int(value)
        case "--verbose-samples":
            overrides.verboseSampleCount = Int(value)
        default:
            print("Unknown option: \(key)")
        }
    }

    return (command: command, overrides: overrides, flags: flags)
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
        print("Usage: kbtrack <command> [options]")
        print("Commands:")
        print("  daemon   - Run monitoring cycle (called by LaunchAgent)")
        print("  status   - Show current tracking status")
        print("  history  - Show completed sessions")
        print("  reset    - Force stop current session")
        print("")
        print("Options:")
        print("  --start-threshold=<percent>")
        print("  --stop-threshold=<percent>")
        print("  --tolerance=<percent>")
        print("  --timeout=<seconds>")
        print("  --grace-cycles=<count>")
        print("  --smooth-window=<samples>")
        print("  --samples-retention=<count>")
        print("  --verbose-samples=<count>")
        print("  --verbose (status command)")
        exit(1)
    }
    
    let (command, overrides, flags) = parseArguments(args: args)
    let config = baseConfig.overriding(overrides)

    switch command {
    case "daemon":
        await runDaemon(config: config)
    case "status":
        let isVerbose = flags.contains("verbose")
        showStatus(config: config, verbose: isVerbose)
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
