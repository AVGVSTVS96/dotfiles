#!/usr/bin/env swift
import Foundation
import CoreBluetooth
import IOBluetooth

// MARK: - Configuration
let KEYBOARD_ADDRESS = "FC:00:72:C2:AC:AF"
let KEYBOARD_NAME = "NuPhy Air75 V3-1"
let BATTERY_SERVICE_UUID = CBUUID(string: "180F")
let BATTERY_LEVEL_UUID = CBUUID(string: "2A19")
let START_THRESHOLD = 85
let STOP_THRESHOLD = 5
let OFFLINE_DROP_TOLERANCE_PERCENT = 5
let CHARGE_TOLERANCE_PERCENT = 7
let CONNECTION_TIMEOUT: TimeInterval = 10.0
let POLL_INTERVAL_SECONDS = 60
let MAX_SAMPLE_INTERVAL_SECONDS = Int.max
let ACCRUAL_CONFIDENCE_THRESHOLD = 0.5
let FAILURE_CONFIDENCE_GRACE = 5
let DEFAULT_WATCH_INTERVAL: TimeInterval = 15
let SAMPLE_CONFIDENCE_THRESHOLD = 0.5

let isoFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

let dataDir = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Library/Application Support/kbtrack")
let sessionFile = dataDir.appendingPathComponent("session.json")
let historyFile = dataDir.appendingPathComponent("sessions.json")
let logFile = dataDir.appendingPathComponent("daemon.log")
let legacyCurrentFile = dataDir.appendingPathComponent("current.json")
let samplesFile = dataDir.appendingPathComponent("samples.jsonl")

// MARK: - Data Models
enum TrackingStatus: String, Codable {
    case idle
    case tracking
    case paused
    case blocked
}

struct LiveSession: Codable {
    var status: TrackingStatus
    var keyboardAddress: String
    var startedAt: String
    var batteryStart: Int
    var lastBattery: Int
    var lowestBattery: Int
    var accumulatedSeconds: Int
    var samples: Int
    var pendingChargeGain: Int
    var consecutiveIncreaseSamples: Int
    var lastSampleAt: String?
    var lastConnectedAt: String?
    var isConnected: Bool
    var consecutiveUnavailableSamples: Int
    var lastIssue: SessionIssue?

    init(status: TrackingStatus,
         keyboardAddress: String,
         startedAt: String,
         batteryStart: Int,
         lastBattery: Int,
         lowestBattery: Int,
         accumulatedSeconds: Int,
         samples: Int,
         pendingChargeGain: Int,
         consecutiveIncreaseSamples: Int,
         lastSampleAt: String?,
         lastConnectedAt: String?,
         isConnected: Bool,
         consecutiveUnavailableSamples: Int = 0,
         lastIssue: SessionIssue? = nil) {
        self.status = status
        self.keyboardAddress = keyboardAddress
        self.startedAt = startedAt
        self.batteryStart = batteryStart
        self.lastBattery = lastBattery
        self.lowestBattery = lowestBattery
        self.accumulatedSeconds = accumulatedSeconds
        self.samples = samples
        self.pendingChargeGain = pendingChargeGain
        self.consecutiveIncreaseSamples = consecutiveIncreaseSamples
        self.lastSampleAt = lastSampleAt
        self.lastConnectedAt = lastConnectedAt
        self.isConnected = isConnected
        self.consecutiveUnavailableSamples = consecutiveUnavailableSamples
        self.lastIssue = lastIssue
    }

    private enum CodingKeys: String, CodingKey {
        case status
        case keyboardAddress
        case startedAt
        case batteryStart
        case lastBattery
        case lowestBattery
        case accumulatedSeconds
        case samples
        case pendingChargeGain
        case consecutiveIncreaseSamples
        case lastSampleAt
        case lastConnectedAt
        case isConnected
        case consecutiveUnavailableSamples
        case lastIssue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(TrackingStatus.self, forKey: .status)
        keyboardAddress = try container.decode(String.self, forKey: .keyboardAddress)
        startedAt = try container.decode(String.self, forKey: .startedAt)
        batteryStart = try container.decode(Int.self, forKey: .batteryStart)
        lastBattery = try container.decode(Int.self, forKey: .lastBattery)
        lowestBattery = try container.decode(Int.self, forKey: .lowestBattery)
        accumulatedSeconds = try container.decode(Int.self, forKey: .accumulatedSeconds)
        samples = try container.decode(Int.self, forKey: .samples)
        pendingChargeGain = try container.decode(Int.self, forKey: .pendingChargeGain)
        consecutiveIncreaseSamples = try container.decode(Int.self, forKey: .consecutiveIncreaseSamples)
        lastSampleAt = try container.decodeIfPresent(String.self, forKey: .lastSampleAt)
        lastConnectedAt = try container.decodeIfPresent(String.self, forKey: .lastConnectedAt)
        isConnected = try container.decodeIfPresent(Bool.self, forKey: .isConnected) ?? false
        consecutiveUnavailableSamples = try container.decodeIfPresent(Int.self, forKey: .consecutiveUnavailableSamples) ?? 0
        lastIssue = try container.decodeIfPresent(SessionIssue.self, forKey: .lastIssue)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(status, forKey: .status)
        try container.encode(keyboardAddress, forKey: .keyboardAddress)
        try container.encode(startedAt, forKey: .startedAt)
        try container.encode(batteryStart, forKey: .batteryStart)
        try container.encode(lastBattery, forKey: .lastBattery)
        try container.encode(lowestBattery, forKey: .lowestBattery)
        try container.encode(accumulatedSeconds, forKey: .accumulatedSeconds)
        try container.encode(samples, forKey: .samples)
        try container.encode(pendingChargeGain, forKey: .pendingChargeGain)
        try container.encode(consecutiveIncreaseSamples, forKey: .consecutiveIncreaseSamples)
        try container.encodeIfPresent(lastSampleAt, forKey: .lastSampleAt)
        try container.encodeIfPresent(lastConnectedAt, forKey: .lastConnectedAt)
        try container.encode(isConnected, forKey: .isConnected)
        try container.encode(consecutiveUnavailableSamples, forKey: .consecutiveUnavailableSamples)
        try container.encodeIfPresent(lastIssue, forKey: .lastIssue)
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
    let samples: Int?
    let lowestBattery: Int?
}

struct SessionsHistory: Codable {
    var sessions: [CompletedSession]
}

enum SessionIssue: String, Codable {
    case bluetoothUnauthorized
    case bluetoothPoweredOff
    case bluetoothUnavailable
    case connectionTimeout
    case peripheralNotFound
    case unknown
}

private struct LegacySessionState: Codable {
    var status: String
    var keyboardAddress: String
    var batteryStart: Int
    var batteryPrevious: Int
    var batteryCurrent: Int
    var connected: Bool
    var accumulatedSeconds: Int
    var startedAt: String
    var lowestBattery: Int?
    var pendingChargeGain: Int?
}

// MARK: - Bluetooth Manager
enum MeasurementFailure: String {
    case peripheralNotFound
    case bluetoothUnauthorized
    case bluetoothPoweredOff
    case timeout
    case bluetoothUnavailable
    case unknown

    var sessionIssue: SessionIssue {
        switch self {
        case .peripheralNotFound:
            return .peripheralNotFound
        case .bluetoothUnauthorized:
            return .bluetoothUnauthorized
        case .bluetoothPoweredOff:
            return .bluetoothPoweredOff
        case .timeout:
            return .connectionTimeout
        case .bluetoothUnavailable:
            return .bluetoothUnavailable
        case .unknown:
            return .unknown
        }
    }
}

enum MeasurementResult {
    case success(batteryPercent: Int)
    case failure(MeasurementFailure)
}

enum ConnectivitySource: String, Codable {
    case coreBluetooth
    case ioBluetooth
    case systemProfiler
}

struct ConnectivityAssessment {
    let isConnected: Bool
    let confidence: Double
    let sources: [ConnectivitySource]
    let issue: SessionIssue?
}

struct ConnectivityProbe {
    let batteryPercent: Int?
    let assessment: ConnectivityAssessment
    let failure: MeasurementFailure?
}

struct SampleRecord: Codable {
    let timestamp: String
    let battery: Int?
    let connected: Bool
    let confidence: Double
    let deltaSeconds: Int
    let sources: [ConnectivitySource]
    let issue: SessionIssue?
    let status: TrackingStatus
}

class BluetoothBatteryReader: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var batteryCharacteristic: CBCharacteristic?
    
    private var continuation: CheckedContinuation<MeasurementResult, Never>?
    private var timeoutTask: Task<Void, Never>?
    private var isCompleted: Bool = false
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }

    func readBattery() async -> MeasurementResult {
        isCompleted = false
        return await withCheckedContinuation { continuation in
            self.continuation = continuation

            timeoutTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(CONNECTION_TIMEOUT * 1_000_000_000))
                if !self.isCompleted, self.continuation != nil {
                    log("Connection timeout")
                    self.complete(with: .failure(.timeout))
                }
            }
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            let peripherals = centralManager.retrieveConnectedPeripherals(withServices: [BATTERY_SERVICE_UUID])
            let nuphyPeripheral = peripherals.first { peripheral in
                peripheral.name?.contains("NuPhy") ?? false || peripheral.name?.contains("Air75") ?? false
            }
            
            guard let peripheral = nuphyPeripheral else {
                log("NuPhy keyboard not connected (found \(peripherals.count) other devices)")
                complete(with: .failure(.peripheralNotFound))
                return
            }
            
            log("Found NuPhy keyboard: \(peripheral.name ?? "Unknown")")
            self.peripheral = peripheral
            peripheral.delegate = self
            
            if peripheral.state == .connected {
                peripheral.discoverServices([BATTERY_SERVICE_UUID])
            } else {
                centralManager.connect(peripheral)
            }
        case .unauthorized:
            log("Bluetooth unauthorized (state: \(central.state.rawValue))")
            complete(with: .failure(.bluetoothUnauthorized))
        case .poweredOff:
            log("Bluetooth powered off")
            complete(with: .failure(.bluetoothPoweredOff))
        case .unsupported:
            log("Bluetooth unsupported on this device")
            complete(with: .failure(.bluetoothUnavailable))
        case .resetting, .unknown:
            log("Bluetooth state transitioning (state: \(central.state.rawValue))")
            // Wait for next state update; timeout will handle if it stalls.
        @unknown default:
            log("Bluetooth state unknown: \(central.state.rawValue)")
            complete(with: .failure(.unknown))
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log("Connected to peripheral")
        peripheral.discoverServices([BATTERY_SERVICE_UUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log("Failed to connect: \(error?.localizedDescription ?? "unknown")")
        complete(with: .failure(.peripheralNotFound))
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            log("Error discovering services: \(error)")
            complete(with: .failure(.unknown))
            return
        }
        
        guard let service = peripheral.services?.first(where: { $0.uuid == BATTERY_SERVICE_UUID }) else {
            log("Battery service not found")
            complete(with: .failure(.peripheralNotFound))
            return
        }
        
        peripheral.discoverCharacteristics([BATTERY_LEVEL_UUID], for: service)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            log("Error discovering characteristics: \(error)")
            complete(with: .failure(.unknown))
            return
        }
        
        guard let characteristic = service.characteristics?.first(where: { $0.uuid == BATTERY_LEVEL_UUID }) else {
            log("Battery characteristic not found")
            complete(with: .failure(.peripheralNotFound))
            return
        }
        
        batteryCharacteristic = characteristic
        peripheral.readValue(for: characteristic)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        log("didUpdateValueFor called, isCompleted: \(isCompleted)")
        
        guard !isCompleted else {
            log("Already completed by timeout, ignoring battery read")
            return
        }

        if let error = error {
            log("Error reading value: \(error)")
            complete(with: .failure(.unknown))
            return
        }
        
        guard let data = characteristic.value, !data.isEmpty else {
            log("No battery data")
            complete(with: .failure(.unknown))
            return
        }
        
        let batteryLevel = Int(data[0])
        log("Battery level: \(batteryLevel)%")
        complete(with: .success(batteryPercent: batteryLevel))
    }
    
    private func cleanup() {
        if let peripheral = peripheral, peripheral.state == .connected {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }

    private func complete(with result: MeasurementResult) {
        guard !isCompleted else { return }
        isCompleted = true
        timeoutTask?.cancel()
        timeoutTask = nil
        if let continuation {
            continuation.resume(returning: result)
            self.continuation = nil
        }
        cleanup()
    }
}

class ConnectivityProvider {
    private let ioAddress = KEYBOARD_ADDRESS.replacingOccurrences(of: ":", with: "-")

    func evaluate() async -> ConnectivityProbe {
        let reader = BluetoothBatteryReader()
        let cbResult = await reader.readBattery()

        switch cbResult {
        case .success(let battery):
            let assessment = ConnectivityAssessment(
                isConnected: true,
                confidence: 1.0,
                sources: [.coreBluetooth],
                issue: nil
            )
            return ConnectivityProbe(batteryPercent: battery, assessment: assessment, failure: nil)

        case .failure(let failure):
            var sources: [ConnectivitySource] = [.coreBluetooth]
            var confidence: Double = 0.0
            var connected = false

            if let ioConnected = queryIOBluetooth() {
                sources.append(.ioBluetooth)
                if ioConnected {
                    connected = true
                    confidence = max(confidence, 0.8)
                }
            }

            if !connected, let profilerConnected = querySystemProfiler() {
                sources.append(.systemProfiler)
                if profilerConnected {
                    connected = true
                    confidence = max(confidence, 0.6)
                }
            }

            let uniqueSources = Array(Set(sources)).sorted { $0.rawValue < $1.rawValue }
            let assessment = ConnectivityAssessment(
                isConnected: connected,
                confidence: confidence,
                sources: uniqueSources,
                issue: failure.sessionIssue
            )
            return ConnectivityProbe(batteryPercent: nil, assessment: assessment, failure: failure)
        }
    }

    private func queryIOBluetooth() -> Bool? {
        guard let device = IOBluetoothDevice(addressString: ioAddress) else {
            return nil
        }
        return device.isConnected()
    }

    private func querySystemProfiler() -> Bool? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["SPBluetoothDataType"]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            log("system_profiler launch failed: \(error.localizedDescription)")
            return nil
        }

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard let text = String(data: data, encoding: .utf8) else {
            return nil
        }

        if let verdict = parseSystemProfiler(text: text, token: KEYBOARD_NAME) {
            return verdict
        }

        let addressToken = ioAddress
        if let verdict = parseSystemProfiler(text: text, token: addressToken) {
            return verdict
        }

        return nil
    }

    private func parseSystemProfiler(text: String, token: String) -> Bool? {
        guard let range = text.range(of: token) else {
            return nil
        }

        let tail = text[range.lowerBound...]
        let lines = tail.split(separator: "\n", maxSplits: 25, omittingEmptySubsequences: false)
        for line in lines {
            if line.contains("Connected:") {
                if line.contains("Yes") { return true }
                if line.contains("No") { return false }
            }
        }
        return nil
    }
}

// MARK: - Utility Functions
func ensureDataDirectory() {
    try? FileManager.default.createDirectory(at: dataDir, withIntermediateDirectories: true)
}

func log(_ message: String) {
    ensureDataDirectory()
    let timestamp = isoFormatter.string(from: Date())
    let logMessage = "[\(timestamp)] \(message)\n"
    
    guard let data = logMessage.data(using: .utf8) else { return }
    
    if FileManager.default.fileExists(atPath: logFile.path) {
        if let fileHandle = try? FileHandle(forWritingTo: logFile) {
            fileHandle.seekToEndOfFile()
            if #available(macOS 10.15.4, *) {
                try? fileHandle.write(contentsOf: data)
            } else {
                fileHandle.write(data)
            }
            try? fileHandle.close()
        }
    } else {
        try? data.write(to: logFile)
    }
}

func formatTime(_ seconds: Int) -> String {
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    return "\(hours)h \(minutes)m"
}

func loadHistory() -> SessionsHistory {
    guard FileManager.default.fileExists(atPath: historyFile.path),
          let data = try? Data(contentsOf: historyFile),
          let history = try? JSONDecoder().decode(SessionsHistory.self, from: data) else {
        return SessionsHistory(sessions: [])
    }
    return history
}

func saveHistory(_ history: SessionsHistory) {
    ensureDataDirectory()
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    if let data = try? encoder.encode(history) {
        try? data.write(to: historyFile)
    }
}

func removeLiveSession() {
    try? FileManager.default.removeItem(at: sessionFile)
}

func saveLiveSession(_ session: LiveSession) {
    ensureDataDirectory()
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    if let data = try? encoder.encode(session) {
        try? data.write(to: sessionFile)
    }
}

func loadLiveSession() -> LiveSession? {
    if FileManager.default.fileExists(atPath: sessionFile.path),
       let data = try? Data(contentsOf: sessionFile),
       let session = try? JSONDecoder().decode(LiveSession.self, from: data) {
        return session
    }
    
    if let migrated = migrateLegacySession() {
        saveLiveSession(migrated)
        return migrated
    }
    
    return nil
}

func migrateLegacySession() -> LiveSession? {
    guard FileManager.default.fileExists(atPath: legacyCurrentFile.path),
          let data = try? Data(contentsOf: legacyCurrentFile),
          let legacy = try? JSONDecoder().decode(LegacySessionState.self, from: data) else {
        return nil
    }
    
    let status: TrackingStatus = legacy.connected ? .tracking : .paused
    let lowest = legacy.lowestBattery ?? legacy.batteryCurrent
    let pending = legacy.pendingChargeGain ?? 0
    let samples = max(legacy.accumulatedSeconds / POLL_INTERVAL_SECONDS, 0)
    
    let session = LiveSession(
        status: status,
        keyboardAddress: legacy.keyboardAddress,
        startedAt: legacy.startedAt,
        batteryStart: legacy.batteryStart,
        lastBattery: legacy.batteryCurrent,
        lowestBattery: lowest,
        accumulatedSeconds: legacy.accumulatedSeconds,
        samples: samples,
        pendingChargeGain: pending,
        consecutiveIncreaseSamples: 0,
        lastSampleAt: nil,
        lastConnectedAt: nil,
        isConnected: legacy.connected,
        consecutiveUnavailableSamples: 0,
        lastIssue: nil
    )
    
    try? FileManager.default.removeItem(at: legacyCurrentFile)
    log("Migrated legacy current session to new session.json format")
    return session
}

func startSession(batteryPercent: Int, now: Date, force: Bool = false) -> LiveSession? {
    guard force || batteryPercent >= START_THRESHOLD else {
        return nil
    }
    
    let timestamp = isoFormatter.string(from: now)
    return LiveSession(
        status: .tracking,
        keyboardAddress: KEYBOARD_ADDRESS,
        startedAt: timestamp,
        batteryStart: batteryPercent,
        lastBattery: batteryPercent,
        lowestBattery: batteryPercent,
        accumulatedSeconds: 0,
        samples: 0,
        pendingChargeGain: 0,
        consecutiveIncreaseSamples: 0,
        lastSampleAt: nil,
        lastConnectedAt: timestamp,
        isConnected: true,
        consecutiveUnavailableSamples: 0,
        lastIssue: nil
    )
}

func finalizeSession(_ session: LiveSession, reason: String, batteryEndOverride: Int? = nil, endedAt: Date = Date()) {
    let history = loadHistory()
    let sessionNum = (history.sessions.last?.sessionNum ?? 0) + 1
    let endedString = isoFormatter.string(from: endedAt)
    let batteryEnd = batteryEndOverride ?? session.lastBattery
    
    let entry = CompletedSession(
        sessionNum: sessionNum,
        started: session.startedAt,
        ended: endedString,
        stopReason: reason,
        batteryStart: session.batteryStart,
        batteryEnd: batteryEnd,
        totalSeconds: session.accumulatedSeconds,
        formatted: formatTime(session.accumulatedSeconds),
        samples: session.samples,
        lowestBattery: session.lowestBattery
    )
    
    var updatedHistory = history
    updatedHistory.sessions.append(entry)
    saveHistory(updatedHistory)
    removeLiveSession()
    log("Session \(sessionNum) archived with reason \(reason)")
}

// MARK: - Sample Recording
func appendSampleRecord(_ record: SampleRecord) {
    ensureDataDirectory()
    let encoder = JSONEncoder()
    if let json = try? encoder.encode(record),
       let line = String(data: json, encoding: .utf8) {
        let data = (line + "\n").data(using: .utf8)!
        if FileManager.default.fileExists(atPath: samplesFile.path) {
            if let handle = try? FileHandle(forWritingTo: samplesFile) {
                handle.seekToEndOfFile()
                if #available(macOS 10.15.4, *) {
                    try? handle.write(contentsOf: data)
                } else {
                    handle.write(data)
                }
                try? handle.close()
            }
        } else {
            try? data.write(to: samplesFile)
        }
    }
}

func loadSamples() -> [SampleRecord] {
    guard FileManager.default.fileExists(atPath: samplesFile.path),
          let content = try? String(contentsOf: samplesFile, encoding: .utf8) else {
        return []
    }
    
    let decoder = JSONDecoder()
    var samples: [SampleRecord] = []
    
    for line in content.split(separator: "\n") {
        if let data = line.data(using: .utf8),
           let sample = try? decoder.decode(SampleRecord.self, from: data) {
            samples.append(sample)
        }
    }
    
    return samples
}

struct DischargeRate {
    let percentPerHour: Double
    let hoursPerPercent: Double
    let sampleCount: Int
    let timeSpanHours: Double
    let batteryDrop: Int
}

func calculateDischargeRate(samples: [SampleRecord], windowSeconds: TimeInterval) -> DischargeRate? {
    let now = Date()
    let cutoff = now.addingTimeInterval(-windowSeconds)
    
    let recentSamples = samples.filter { sample in
        guard let date = isoFormatter.date(from: sample.timestamp) else { return false }
        return date >= cutoff && sample.battery != nil
    }.sorted { s1, s2 in
        guard let d1 = isoFormatter.date(from: s1.timestamp),
              let d2 = isoFormatter.date(from: s2.timestamp) else { return false }
        return d1 < d2
    }
    
    guard recentSamples.count >= 2,
          let firstBattery = recentSamples.first?.battery,
          let lastBattery = recentSamples.last?.battery,
          let firstDate = isoFormatter.date(from: recentSamples.first!.timestamp),
          let lastDate = isoFormatter.date(from: recentSamples.last!.timestamp) else {
        return nil
    }
    
    let timeSpan = lastDate.timeIntervalSince(firstDate)
    guard timeSpan > 60 else { return nil }
    
    let batteryDrop = firstBattery - lastBattery
    let hours = timeSpan / 3600.0
    
    if batteryDrop > 0 && hours > 0 {
        let pph = Double(batteryDrop) / hours
        let hpp = hours / Double(batteryDrop)
        return DischargeRate(
            percentPerHour: pph,
            hoursPerPercent: hpp,
            sampleCount: recentSamples.count,
            timeSpanHours: hours,
            batteryDrop: batteryDrop
        )
    }
    
    return nil
}

func computeTrendSlope(rates: [Double], timestamps: [Date], sessionStart: Date) -> Double {
    guard rates.count >= 3, rates.count == timestamps.count else { return 0.0 }
    
    // Convert timestamps to elapsed hours from session start
    let hours = timestamps.map { $0.timeIntervalSince(sessionStart) / 3600.0 }
    
    // Simple linear regression: slope = Σ((x - x̄)(y - ȳ)) / Σ((x - x̄)²)
    let n = Double(rates.count)
    let meanX = hours.reduce(0.0, +) / n
    let meanY = rates.reduce(0.0, +) / n
    
    var numerator = 0.0
    var denominator = 0.0
    
    for i in 0..<rates.count {
        let dx = hours[i] - meanX
        let dy = rates[i] - meanY
        numerator += dx * dy
        denominator += dx * dx
    }
    
    guard denominator > 0.001 else { return 0.0 }
    return numerator / denominator
}

struct DischargeRateStats {
    let rates: [Double]
    let filteredRates: [Double]
    let mean: Double
    let min: Double
    let max: Double
    let stddev: Double
    let range: Double
    let slope: Double
    let sampleTimestamps: [Date]
}

func calculateDischargeRateStatistics(samples: [SampleRecord], segmentMinutes: Int = 60) -> DischargeRateStats? {
    guard samples.count >= 10 else { return nil }
    
    let sortedSamples = samples.filter { $0.battery != nil }.sorted { s1, s2 in
        guard let d1 = isoFormatter.date(from: s1.timestamp),
              let d2 = isoFormatter.date(from: s2.timestamp) else { return false }
        return d1 < d2
    }
    
    guard sortedSamples.count >= 10,
          let sessionStart = isoFormatter.date(from: sortedSamples.first!.timestamp) else { return nil }
    
    var rates: [Double] = []
    var timestamps: [Date] = []
    let segmentSeconds = Double(segmentMinutes * 60)
    let minSegmentSeconds = segmentSeconds * 0.5  // Require at least 30 min for 1hr segments
    
    // Use fixed window approach for consistent measurements
    var i = 0
    while i < sortedSamples.count - 1 {
        guard let startDate = isoFormatter.date(from: sortedSamples[i].timestamp),
              let startBattery = sortedSamples[i].battery else {
            i += 1
            continue
        }
        
        // Look ahead to find segments of approximately the target duration
        for j in (i + 1)..<sortedSamples.count {
            guard let endDate = isoFormatter.date(from: sortedSamples[j].timestamp),
                  let endBattery = sortedSamples[j].battery else {
                continue
            }
            
            let timeSpan = endDate.timeIntervalSince(startDate)
            
            // Accept segments within 20% of target, but require minimum duration
            if timeSpan >= minSegmentSeconds && timeSpan <= segmentSeconds * 1.2 {
                let hours = timeSpan / 3600.0
                let drop = startBattery - endBattery
                
                // Include ALL measurements for time tracking (even 0 or negative)
                if hours > 0 {
                    let rate = Double(drop) / hours
                    rates.append(rate)
                    timestamps.append(endDate)
                }
                
                break
            }
            
            // Stop looking if we've gone too far past the target
            if timeSpan > segmentSeconds * 1.5 {
                break
            }
        }
        
        // Slide window forward
        i += max(1, sortedSamples.count / 50)
    }
    
    guard rates.count >= 3 else { return nil }
    
    // Filter rates > 0.01%/hr for statistics (exclude idle/charge periods)
    let filteredRates = rates.filter { $0 > 0.01 }
    
    // If too few actual discharge samples, use all rates for basic stats
    let statsRates = filteredRates.count >= 3 ? filteredRates : rates
    
    let mean = statsRates.reduce(0.0, +) / Double(statsRates.count)
    let min = statsRates.min() ?? 0
    let max = statsRates.max() ?? 0
    
    let variance = statsRates.map { pow($0 - mean, 2) }.reduce(0.0, +) / Double(statsRates.count)
    let stddev = sqrt(variance)
    let range = max - min
    
    // Compute slope using filtered rates for trend detection
    let slope = filteredRates.count >= 3 ? 
        computeTrendSlope(rates: filteredRates, timestamps: Array(timestamps.suffix(filteredRates.count)), sessionStart: sessionStart) : 
        0.0
    
    return DischargeRateStats(
        rates: rates,
        filteredRates: filteredRates,
        mean: mean,
        min: min,
        max: max,
        stddev: stddev,
        range: range,
        slope: slope,
        sampleTimestamps: timestamps
    )
}

func getTrendIndicator(recent: Double, baseline: Double, threshold: Double = 0.15) -> String {
    let change = (recent - baseline) / baseline
    if abs(change) < threshold {
        return "→"
    } else if change > 0 {
        return "↑"
    } else {
        return "↓"
    }
}

// MARK: - Daemon Logic
func runDaemon() async {
    log("=== Daemon cycle started ===")
    let now = Date()
    let provider = ConnectivityProvider()
    let probe = await provider.evaluate()
    var session = loadLiveSession()
    
    log("Probe: battery=\(probe.batteryPercent?.description ?? "nil"), connected=\(probe.assessment.isConnected), confidence=\(String(format: "%.2f", probe.assessment.confidence)), sources=\(probe.assessment.sources.map { $0.rawValue }.joined(separator: ","))")
    
    // Determine if we should accrue time this cycle
    let allowAccrual = probe.batteryPercent != nil || probe.assessment.confidence >= ACCRUAL_CONFIDENCE_THRESHOLD
    
    // If no active session, try to start one if we have a battery reading
    if session == nil {
        if let batteryPercent = probe.batteryPercent, batteryPercent > 0 {
            if let newSession = startSession(batteryPercent: batteryPercent, now: now, force: false) {
                log("Starting new session at \(batteryPercent)%")
                saveLiveSession(newSession)
                session = newSession
            } else {
                log("No active session; start conditions not met")
                log("=== Daemon cycle completed ===")
                return
            }
        } else {
            log("No active session and no battery reading to start one")
            log("=== Daemon cycle completed ===")
            return
        }
    }
    
    guard var liveSession = session else {
        log("Unable to load session")
        log("=== Daemon cycle completed ===")
        return
    }
    
    // Calculate deltaSeconds for time accrual
    let lastSampleDate = liveSession.lastSampleAt.flatMap { isoFormatter.date(from: $0) }
    let deltaSeconds: Int
    if let lastSampleDate {
        deltaSeconds = min(max(Int(now.timeIntervalSince(lastSampleDate)), 0), MAX_SAMPLE_INTERVAL_SECONDS)
    } else {
        deltaSeconds = 0
    }
    
    // Update session state based on probe
    liveSession.isConnected = probe.assessment.isConnected
    liveSession.lastIssue = probe.assessment.issue
    
    // Handle case where we have a battery reading
    if let batteryPercent = probe.batteryPercent {
        log("Battery reading: \(batteryPercent)%")
        
        // Skip 0% readings as they're unreliable
        if batteryPercent == 0 {
            log("Received 0% reading; skipping update")
            liveSession.consecutiveUnavailableSamples = 0
            saveLiveSession(liveSession)
            
            let sampleRecord = SampleRecord(
                timestamp: isoFormatter.string(from: now),
                battery: nil,
                connected: probe.assessment.isConnected,
                confidence: probe.assessment.confidence,
                deltaSeconds: 0,
                sources: probe.assessment.sources,
                issue: probe.assessment.issue,
                status: liveSession.status
            )
            appendSampleRecord(sampleRecord)
            log("=== Daemon cycle completed ===")
            return
        }
        
        // Reset failure counters on successful reading
        liveSession.consecutiveUnavailableSamples = 0
        
        // Check for offline_drop scenario
        if liveSession.status == .paused || liveSession.status == .blocked {
            let drop = liveSession.lastBattery - batteryPercent
            if drop > OFFLINE_DROP_TOLERANCE_PERCENT {
                log("Battery dropped \(drop)% while offline (\(liveSession.lastBattery)% → \(batteryPercent)%); closing session")
                liveSession.lastBattery = batteryPercent
                liveSession.lowestBattery = min(liveSession.lowestBattery, batteryPercent)
                finalizeSession(liveSession, reason: "offline_drop", batteryEndOverride: batteryPercent, endedAt: now)
                
                if let newSession = startSession(batteryPercent: batteryPercent, now: now, force: true) {
                    log("Starting new session after offline drop at \(batteryPercent)%")
                    saveLiveSession(newSession)
                }
                log("=== Daemon cycle completed ===")
                return
            } else {
                log("Keyboard reconnected; resuming session at \(batteryPercent)%")
                liveSession.status = .tracking
                liveSession.pendingChargeGain = 0
                liveSession.consecutiveIncreaseSamples = 0
            }
        }
        
        // Promote idle to tracking
        if liveSession.status == .idle {
            log("Session in idle state; promoting to tracking")
            liveSession.status = .tracking
        }
        
        // Accrue time
        liveSession.accumulatedSeconds += deltaSeconds
        liveSession.samples += 1
        liveSession.lastSampleAt = isoFormatter.string(from: now)
        if probe.assessment.isConnected {
            liveSession.lastConnectedAt = liveSession.lastSampleAt
        }
        liveSession.status = .tracking
        
        let previousBattery = liveSession.lastBattery
        
        // Check for battery_depleted
        if batteryPercent <= STOP_THRESHOLD {
            liveSession.lastBattery = batteryPercent
            liveSession.lowestBattery = min(liveSession.lowestBattery, batteryPercent)
            log("Battery reached \(batteryPercent)% (≤ \(STOP_THRESHOLD)%); completing session")
            finalizeSession(liveSession, reason: "battery_depleted", batteryEndOverride: batteryPercent, endedAt: now)
            log("=== Daemon cycle completed ===")
            return
        }
        
        // Handle battery changes
        if liveSession.samples == 1 {
            liveSession.lastBattery = batteryPercent
            liveSession.lowestBattery = min(liveSession.lowestBattery, batteryPercent)
        } else {
            if batteryPercent > previousBattery {
                let increase = batteryPercent - previousBattery
                liveSession.pendingChargeGain += increase
                liveSession.consecutiveIncreaseSamples += 1
                let increaseFromLowest = batteryPercent - liveSession.lowestBattery
                log("Battery increase detected: +\(increase)% (\(previousBattery)% → \(batteryPercent)%); accumulated +\(liveSession.pendingChargeGain)% (+\(increaseFromLowest)% from lowest)")
                
                if liveSession.pendingChargeGain >= CHARGE_TOLERANCE_PERCENT &&
                    liveSession.consecutiveIncreaseSamples >= 2 &&
                    increaseFromLowest >= CHARGE_TOLERANCE_PERCENT {
                    log("Charging trend confirmed; completing session")
                    liveSession.lastBattery = batteryPercent
                    finalizeSession(liveSession, reason: "charging_detected", batteryEndOverride: batteryPercent, endedAt: now)
                    log("=== Daemon cycle completed ===")
                    return
                }
            } else if batteryPercent < previousBattery {
                let drop = previousBattery - batteryPercent
                log("Battery decreased \(drop)% (\(previousBattery)% → \(batteryPercent)%)")
                liveSession.pendingChargeGain = 0
                liveSession.consecutiveIncreaseSamples = 0
                liveSession.lowestBattery = min(liveSession.lowestBattery, batteryPercent)
            } else {
                if liveSession.consecutiveIncreaseSamples > 0 {
                    log("Battery steady at \(batteryPercent)% (resetting increase counter)")
                }
                liveSession.consecutiveIncreaseSamples = 0
            }
            liveSession.lastBattery = batteryPercent
        }
        
        saveLiveSession(liveSession)
        
        let sampleRecord = SampleRecord(
            timestamp: isoFormatter.string(from: now),
            battery: batteryPercent,
            connected: probe.assessment.isConnected,
            confidence: probe.assessment.confidence,
            deltaSeconds: deltaSeconds,
            sources: probe.assessment.sources,
            issue: probe.assessment.issue,
            status: liveSession.status
        )
        appendSampleRecord(sampleRecord)
        
    } else {
        // No battery reading, but check if we should accrue time based on confidence
        log("No battery reading available")
        liveSession.consecutiveUnavailableSamples += 1
        
        if allowAccrual && liveSession.consecutiveUnavailableSamples <= FAILURE_CONFIDENCE_GRACE {
            log("Confidence \(String(format: "%.2f", probe.assessment.confidence)) ≥ threshold; accruing time (failure \(liveSession.consecutiveUnavailableSamples)/\(FAILURE_CONFIDENCE_GRACE))")
            liveSession.accumulatedSeconds += deltaSeconds
            liveSession.samples += 1
            liveSession.lastSampleAt = isoFormatter.string(from: now)
            
            let sampleRecord = SampleRecord(
                timestamp: isoFormatter.string(from: now),
                battery: nil,
                connected: probe.assessment.isConnected,
                confidence: probe.assessment.confidence,
                deltaSeconds: deltaSeconds,
                sources: probe.assessment.sources,
                issue: probe.assessment.issue,
                status: liveSession.status
            )
            appendSampleRecord(sampleRecord)
            
        } else {
            log("Confidence too low or grace period exceeded; pausing accrual (failure \(liveSession.consecutiveUnavailableSamples)/\(FAILURE_CONFIDENCE_GRACE))")
            
            // After grace period, set appropriate status
            if liveSession.consecutiveUnavailableSamples > FAILURE_CONFIDENCE_GRACE {
                if let issue = probe.assessment.issue {
                    switch issue {
                    case .bluetoothUnauthorized, .bluetoothPoweredOff, .bluetoothUnavailable, .connectionTimeout, .unknown:
                        if liveSession.status != .blocked {
                            log("Setting session to blocked due to: \(issue.rawValue)")
                            liveSession.status = .blocked
                        }
                    case .peripheralNotFound:
                        if liveSession.status != .paused {
                            log("Setting session to paused (peripheral not found)")
                            liveSession.status = .paused
                        }
                        liveSession.lastConnectedAt = nil
                        liveSession.pendingChargeGain = 0
                        liveSession.consecutiveIncreaseSamples = 0
                    }
                } else {
                    if liveSession.status != .paused {
                        log("Setting session to paused (low confidence)")
                        liveSession.status = .paused
                    }
                }
            }
            
            let sampleRecord = SampleRecord(
                timestamp: isoFormatter.string(from: now),
                battery: nil,
                connected: probe.assessment.isConnected,
                confidence: probe.assessment.confidence,
                deltaSeconds: 0,
                sources: probe.assessment.sources,
                issue: probe.assessment.issue,
                status: liveSession.status
            )
            appendSampleRecord(sampleRecord)
        }
        
        saveLiveSession(liveSession)
    }
    
    log("=== Daemon cycle completed ===")
}

// MARK: - CLI Commands
func showStatus() {
    guard let session = loadLiveSession() else {
        print("No active tracking session")
        return
    }
    
    let percentUsed = session.batteryStart - session.lastBattery
    let hours = Double(session.accumulatedSeconds) / 3600.0
    let connectionLabel: String
    switch session.status {
    case .tracking:
        connectionLabel = session.isConnected ? "Connected ✓" : "Tracking ✓"
    case .paused:
        connectionLabel = "Disconnected ∅"
    case .idle:
        connectionLabel = "Idle"
    case .blocked:
        connectionLabel = "Permission blocked ⚠︎"
    }
    
    print(String(repeating: "=", count: 60))
    print("NuPhy Air75 V3-1: \(connectionLabel)")
    print(String(repeating: "=", count: 60))
    
    print("\n📊 Current Status:")
    print("  Battery: \(session.lastBattery)% (started at \(session.batteryStart)%)")
    print("  Used: \(percentUsed)%")
    print("  Connected time: \(formatTime(session.accumulatedSeconds))")
    print("  Started: \(session.startedAt)")

    if let issue = session.lastIssue {
        let issueDescription: String
        switch issue {
        case .bluetoothUnauthorized:
            issueDescription = "Bluetooth permission denied. Allow kbtrack in System Settings → Privacy & Security → Bluetooth."
        case .bluetoothPoweredOff:
            issueDescription = "Bluetooth is powered off. Turn Bluetooth back on to resume sampling."
        case .bluetoothUnavailable:
            issueDescription = "Bluetooth hardware unavailable. Check Bluetooth settings and retry."
        case .connectionTimeout:
            issueDescription = "Bluetooth timed out. kbtrack will retry automatically."
        case .peripheralNotFound:
            issueDescription = "Keyboard not detected. Ensure it is connected and awake."
        case .unknown:
            issueDescription = "Unknown Bluetooth error."
        }
        print("\n⚠️ Last issue: \(issueDescription)")
    }
    
    let samples = loadSamples()
    
    if percentUsed > 0 && hours > 0.1 {
        let hoursPerPercent = hours / Double(percentUsed)
        let dischargeRate = Double(percentUsed) / hours
        
        let remainingPercent = max(session.lastBattery - STOP_THRESHOLD, 0)
        let estimatedRemainingHours = Double(remainingPercent) * hoursPerPercent
        
        let totalUsablePercent = session.batteryStart - STOP_THRESHOLD
        let estimatedTotalHours = Double(totalUsablePercent) * hoursPerPercent
        
        print("\n⚡️ Discharge Rate (Session Average):")
        print("  Losing \(String(format: "%.2f", dischargeRate))% per hour")
        print("  1% battery lasts ~\(String(format: "%.1f", hoursPerPercent)) hours")
        
        if samples.count >= 2 {
            print("\n📈 Recent Discharge Rates:")
            
            let rate15m = calculateDischargeRate(samples: samples, windowSeconds: 15 * 60)
            let rate1h = calculateDischargeRate(samples: samples, windowSeconds: 60 * 60)
            let rate3h = calculateDischargeRate(samples: samples, windowSeconds: 3 * 60 * 60)
            let rate12h = calculateDischargeRate(samples: samples, windowSeconds: 12 * 60 * 60)
            let rate48h = calculateDischargeRate(samples: samples, windowSeconds: 48 * 60 * 60)
            
            // 15m window
            if let rate15m = rate15m {
                let trend = rate1h != nil ? getTrendIndicator(recent: rate15m.percentPerHour, baseline: rate1h!.percentPerHour) : ""
                print("  Last 15m: -\(rate15m.batteryDrop)% in \(String(format: "%.1f", rate15m.timeSpanHours * 60))min = \(String(format: "%.2f", rate15m.percentPerHour))%/hr \(trend) (\(rate15m.sampleCount) samples)")
                if let rate1h = rate1h {
                    let change = ((rate15m.percentPerHour - rate1h.percentPerHour) / rate1h.percentPerHour) * 100
                    print("            \(change > 0 ? "+" : "")\(String(format: "%.1f", change))% vs 1h avg")
                }
            } else {
                print("  Last 15m: No discharge (stable)")
            }
            
            // 1h window
            if let rate1h = rate1h {
                let trend = rate3h != nil ? getTrendIndicator(recent: rate1h.percentPerHour, baseline: rate3h!.percentPerHour) : ""
                print("  Last 1h:  -\(rate1h.batteryDrop)% in \(String(format: "%.1f", rate1h.timeSpanHours))hr = \(String(format: "%.2f", rate1h.percentPerHour))%/hr \(trend) (\(rate1h.sampleCount) samples)")
                if let rate3h = rate3h {
                    let change = ((rate1h.percentPerHour - rate3h.percentPerHour) / rate3h.percentPerHour) * 100
                    print("            \(change > 0 ? "+" : "")\(String(format: "%.1f", change))% vs 3h avg")
                }
            } else {
                print("  Last 1h:  No discharge (stable)")
            }
            
            // 3h window
            if let rate3h = rate3h {
                let trend = rate12h != nil ? getTrendIndicator(recent: rate3h.percentPerHour, baseline: rate12h!.percentPerHour) : ""
                print("  Last 3h:  -\(rate3h.batteryDrop)% in \(String(format: "%.1f", rate3h.timeSpanHours))hr = \(String(format: "%.2f", rate3h.percentPerHour))%/hr \(trend) (\(rate3h.sampleCount) samples)")
                if let rate12h = rate12h {
                    let change = ((rate3h.percentPerHour - rate12h.percentPerHour) / rate12h.percentPerHour) * 100
                    print("            \(change > 0 ? "+" : "")\(String(format: "%.1f", change))% vs 12h avg")
                }
            } else {
                print("  Last 3h:  No discharge (stable)")
            }
            
            // 12h window
            if let rate12h = rate12h {
                let trend = rate48h != nil ? getTrendIndicator(recent: rate12h.percentPerHour, baseline: rate48h!.percentPerHour) : ""
                print("  Last 12h: -\(rate12h.batteryDrop)% in \(String(format: "%.1f", rate12h.timeSpanHours))hr = \(String(format: "%.2f", rate12h.percentPerHour))%/hr \(trend) (\(rate12h.sampleCount) samples)")
                if let rate48h = rate48h {
                    let change = ((rate12h.percentPerHour - rate48h.percentPerHour) / rate48h.percentPerHour) * 100
                    print("            \(change > 0 ? "+" : "")\(String(format: "%.1f", change))% vs 48h avg")
                }
            } else {
                print("  Last 12h: No discharge (stable)")
            }
            
            // 48h window
            if let rate48h = rate48h {
                let trend = getTrendIndicator(recent: rate48h.percentPerHour, baseline: dischargeRate)
                print("  Last 48h: -\(rate48h.batteryDrop)% in \(String(format: "%.1f", rate48h.timeSpanHours))hr = \(String(format: "%.2f", rate48h.percentPerHour))%/hr \(trend) (\(rate48h.sampleCount) samples)")
                let change = ((rate48h.percentPerHour - dischargeRate) / dischargeRate) * 100
                print("            \(change > 0 ? "+" : "")\(String(format: "%.1f", change))% vs session avg")
            } else {
                print("  Last 48h: No discharge (stable)")
            }
            
            print("\n📊 Discharge Rate Analysis:")
            if let stats = calculateDischargeRateStatistics(samples: samples, segmentMinutes: 60) {
                print("  Historical rates (1hr segments):")
                print("    Mean: \(String(format: "%.2f", stats.mean))%/hr")
                print("    Range: \(String(format: "%.2f", stats.min))%/hr - \(String(format: "%.2f", stats.max))%/hr (Δ\(String(format: "%.2f", stats.range))%/hr)")
                print("    Std Dev: ±\(String(format: "%.2f", stats.stddev))%/hr")
                
                // Variability with better handling
                if stats.filteredRates.count < 3 {
                    print("    Variability: N/A (sparse discharge data, range: \(String(format: "%.2f", stats.min))-\(String(format: "%.2f", stats.max))%/hr)")
                } else if stats.mean > 0.01 {
                    let variability = (stats.range / stats.mean) * 100
                    let cappedVariability = min(variability, 200.0)
                    let stability = max(0, 100 - (stats.stddev / stats.mean * 100))
                    
                    if variability > 200 && stats.mean < 0.05 {
                        print("    Variability: \(String(format: "%.1f", cappedVariability))% (capped, due to sparse drops)")
                    } else {
                        print("    Variability: \(String(format: "%.1f", cappedVariability))%")
                    }
                    print("    Stability: \(String(format: "%.0f", max(stability, 0)))%")
                }
                
                // Slope-based trend detection
                if stats.filteredRates.count >= 3 {
                    let slopeThreshold = 0.03  // %/hr per hour
                    
                    if stats.slope > slopeThreshold {
                        let recentAvg = stats.filteredRates.suffix(stats.filteredRates.count / 3).reduce(0.0, +) / Double(stats.filteredRates.count / 3)
                        let oldAvg = stats.filteredRates.prefix(stats.filteredRates.count / 3).reduce(0.0, +) / Double(stats.filteredRates.count / 3)
                        let change = oldAvg > 0.01 ? ((recentAvg - oldAvg) / oldAvg * 100) : 0
                        print("    Trend: ↑ discharge increasing (slope: +\(String(format: "%.3f", stats.slope))%/hr², \(change > 0 ? "+" : "")\(String(format: "%.1f", change))% recent vs early)")
                    } else if stats.slope < -slopeThreshold {
                        let recentAvg = stats.filteredRates.suffix(stats.filteredRates.count / 3).reduce(0.0, +) / Double(stats.filteredRates.count / 3)
                        let oldAvg = stats.filteredRates.prefix(stats.filteredRates.count / 3).reduce(0.0, +) / Double(stats.filteredRates.count / 3)
                        let change = oldAvg > 0.01 ? ((recentAvg - oldAvg) / oldAvg * 100) : 0
                        print("    Trend: ↓ discharge decreasing (slope: \(String(format: "%.3f", stats.slope))%/hr², \(change > 0 ? "+" : "")\(String(format: "%.1f", change))% recent vs early)")
                    } else {
                        let recentAvg = stats.filteredRates.suffix(max(3, stats.filteredRates.count / 5)).reduce(0.0, +) / Double(max(3, stats.filteredRates.count / 5))
                        if recentAvg < 0.05 {
                            print("    Trend: → stable (negligible recent discharge)")
                        } else {
                            print("    Trend: → stable (consistent discharge rate)")
                        }
                    }
                } else if stats.rates.count >= 3 {
                    let recentAvg = stats.rates.suffix(max(3, stats.rates.count / 3)).reduce(0.0, +) / Double(max(3, stats.rates.count / 3))
                    if recentAvg < 0.05 {
                        print("    Trend: → stable (minimal discharge throughout)")
                    } else {
                        print("    Trend: N/A (insufficient active discharge data)")
                    }
                }
                
                print("    Data points: \(stats.rates.count) hourly segments (\(stats.filteredRates.count) with discharge)")
                
                // Overall trend summary
                let recentRate = rate12h?.percentPerHour ?? rate48h?.percentPerHour ?? dischargeRate
                if recentRate < 0.10 {
                    print("\n  Summary: Battery extremely stable recently (minimal discharge).")
                } else if stats.slope < -0.03 {
                    print("\n  Summary: Discharge rate improving over time (recent better than early).")
                } else if stats.slope > 0.03 {
                    print("\n  Summary: Discharge rate increasing (consider checking for changes in usage).")
                } else {
                    print("\n  Summary: Discharge rate consistent and predictable.")
                }
            }
            
            print("\n  Total samples recorded: \(samples.count)")
        }
        
        print("\n🔋 Estimates:")
        print("  Remaining: ~\(formatTime(Int(estimatedRemainingHours * 3600))) (\(session.lastBattery)% → \(STOP_THRESHOLD)%)")
        print("  Total life: ~\(formatTime(Int(estimatedTotalHours * 3600))) (\(session.batteryStart)% → \(STOP_THRESHOLD)%)")
        
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
        if let samples = session.samples {
            print("  Samples: \(samples)")
        }
        print("")
    }
}

func resetSession() {
    guard let session = loadLiveSession() else {
        print("No active session to reset")
        return
    }
    
    finalizeSession(session, reason: "manual_reset")
    print("Session reset and saved to history")
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

Task {
    await main()
    exit(0)
}

RunLoop.main.run()
