import Foundation
import CuprimCore

/// Runs a local process, draining stdout while it runs so the pipe cannot fill.
public enum ProcessRunner {
    public static let defaultTimeout: TimeInterval = 4
    public static let maxOutputBytes = 256_000

    public static func run(
        executable: String,
        arguments: [String],
        timeout: TimeInterval = defaultTimeout
    ) async -> String {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: runBlocking(executable: executable, arguments: arguments, timeout: timeout))
            }
        }
    }

    public static func runBlocking(
        executable: String,
        arguments: [String],
        timeout: TimeInterval = defaultTimeout
    ) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        let stdout = Pipe()
        process.standardOutput = stdout
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return ""
        }

        let deadline = Date().addingTimeInterval(timeout)
        var collected = Data()
        let handle = stdout.fileHandleForReading

        while process.isRunning {
            if Date() > deadline {
                process.terminate()
                break
            }
            let chunk = handle.availableData
            if !chunk.isEmpty {
                if collected.count < maxOutputBytes {
                    let remaining = maxOutputBytes - collected.count
                    collected.append(chunk.prefix(remaining))
                }
            } else {
                Thread.sleep(forTimeInterval: 0.02)
            }
        }

        if collected.count < maxOutputBytes {
            let rest = handle.readDataToEndOfFile()
            collected.append(rest.prefix(maxOutputBytes - collected.count))
        }
        return String(data: collected, encoding: .utf8) ?? ""
    }
}
