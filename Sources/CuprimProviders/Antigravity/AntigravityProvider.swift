import Foundation
import CuprimCore

public struct AntigravityProvider: ProviderRuntime {
    public let id: ProviderID = .antigravity

    public init() {}

    public func hasLocalCredentials() async -> Bool {
        if await hasAgyBinary() { return true }
        if await hasKeychainCredentials() { return true }
        return !(await runningCandidatePIDs()).isEmpty
    }

    public func refresh() async throws -> ProviderSnapshot {
        let ports = await discoverLoopbackPorts()
        NSLog("[Cuprim] antigravity probe ports=%@", ports.map(String.init).joined(separator: ","))
        if ports.isEmpty {
            if await hasLocalCredentials() {
                throw ProviderError.unavailable
            }
            throw ProviderError.signedOut
        }

        var lastError: Error = ProviderError.unavailable
        for port in ports {
            for scheme in ["https", "http"] {
                do {
                    let summary = try await post(scheme: scheme, port: port, method: "RetrieveUserQuotaSummary")
                    let metrics = try AntigravityQuotaMapping.metrics(fromSummaryJSON: summary)
                    guard !metrics.isEmpty else { continue }
                    let plan = try? await fetchPlanName(scheme: scheme, port: port)
                    return ProviderSnapshot(
                        id: .antigravity,
                        planName: plan,
                        metrics: metrics,
                        status: .ok,
                        fetchedAt: .now
                    )
                } catch {
                    lastError = error
                }
            }
        }
        throw lastError
    }

    private func fetchPlanName(scheme: String, port: Int) async throws -> String? {
        let data = try await post(scheme: scheme, port: port, method: "GetUserStatus")
        return AntigravityQuotaMapping.planName(fromStatusJSON: data)
    }

    private func post(scheme: String, port: Int, method: String) async throws -> Data {
        let url = URL(string: "\(scheme)://127.0.0.1:\(port)/exa.language_server_pb.LanguageServerService/\(method)")!
        var request = URLRequest(url: url, timeoutInterval: 8)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("1", forHTTPHeaderField: "Connect-Protocol-Version")
        request.httpBody = Data(#"{"ideName":"antigravity","extensionName":"antigravity","locale":"en","ideVersion":"unknown"}"#.utf8)

        let (data, response) = try await LoopbackClient.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ProviderError.unavailable
        }
        try HTTPResponseMapping.throwIfFailed(http, credentialsPresent: true)
        if data.count > HTTPResponseMapping.maxResponseBytes {
            throw ProviderError.decode
        }
        return data
    }

    private func discoverLoopbackPorts() async -> [Int] {
        let output = await ProcessRunner.run(executable: "/usr/sbin/lsof", arguments: ["-nP", "-iTCP", "-sTCP:LISTEN"])
        var ports: [Int] = []
        var seen = Set<Int>()
        for line in output.split(separator: "\n") {
            let command = line.split(whereSeparator: \.isWhitespace).first.map(String.init)?.lowercased() ?? ""
            guard command == "agy"
                    || command.contains("antigravity")
                    || command.contains("language_server")
            else { continue }
            if command.contains("language_server"), !line.lowercased().contains("antigravity") {
                continue
            }
            guard let range = line.range(of: #":(\d+)\s+\(LISTEN\)"#, options: .regularExpression) else {
                continue
            }
            let digits = line[range].filter(\.isNumber)
            if let port = Int(digits), port > 0, seen.insert(port).inserted {
                ports.append(port)
            }
        }
        return ports
    }

    private func runningCandidatePIDs() async -> [Int32] {
        let output = await ProcessRunner.run(executable: "/bin/ps", arguments: ["-ax", "-o", "pid=,command="])
        var pids: [Int32] = []
        for line in output.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard let space = trimmed.firstIndex(of: " ") else { continue }
            let pidText = trimmed[..<space]
            let command = trimmed[trimmed.index(after: space)...].lowercased()
            let name = URL(fileURLWithPath: command.split(whereSeparator: \.isWhitespace).first.map(String.init) ?? "").lastPathComponent
            let match = name == "agy"
                || command.contains("antigravity-cli")
                || command.contains("antigravity_cli")
                || (command.contains("language_server") && command.contains("antigravity"))
            guard let pid = Int32(pidText), match else { continue }
            pids.append(pid)
        }
        return pids
    }

    private func hasAgyBinary() async -> Bool {
        let home = NSHomeDirectory()
        let candidates = [
            "\(home)/.local/bin/agy",
            "/opt/homebrew/bin/agy",
            "/usr/local/bin/agy"
        ]
        if candidates.contains(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
            return true
        }
        let path = await ProcessRunner.run(executable: "/usr/bin/which", arguments: ["agy"])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return !path.isEmpty && FileManager.default.isExecutableFile(atPath: path)
    }

    private func hasKeychainCredentials() async -> Bool {
        let output = await ProcessRunner.run(
            executable: "/usr/bin/security",
            arguments: ["find-generic-password", "-s", "gemini", "-a", "antigravity"]
        )
        return output.contains("\"acct\"") || output.contains("svce")
    }
}

private final class LoopbackClient: NSObject, URLSessionDelegate, @unchecked Sendable {
    static let shared = LoopbackClient()

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 8
        config.waitsForConnectivity = false
        config.urlCache = nil
        config.httpCookieStorage = nil
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        let host = challenge.protectionSpace.host
        guard host == "127.0.0.1" || host == "localhost",
              let trust = challenge.protectionSpace.serverTrust
        else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        completionHandler(.useCredential, URLCredential(trust: trust))
    }
}
