import Foundation
import CuprimCore

public struct HTTPClient: Sendable {
    public static let maxResponseBytes = HTTPResponseMapping.maxResponseBytes

    private let session: URLSession
    public var timeout: TimeInterval

    public init(session: URLSession? = nil, timeout: TimeInterval = 15) {
        self.timeout = timeout
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = timeout
            config.timeoutIntervalForResource = timeout + 5
            config.waitsForConnectivity = false
            config.httpCookieStorage = nil
            config.urlCache = nil
            self.session = URLSession(configuration: config)
        }
    }

    public func get(url: URL, headers: [String: String] = [:]) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "GET"
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        return try await perform(request)
    }

    public func post(url: URL, headers: [String: String] = [:], body: Data?) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.httpBody = body
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        return try await perform(request)
    }

    private func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw mappedTransportError(error)
        }
        guard let http = response as? HTTPURLResponse else {
            throw ProviderError.unavailable
        }
        if data.count > Self.maxResponseBytes {
            NSLog("[Cuprim] HTTP response exceeded size cap (%d bytes)", data.count)
            throw ProviderError.malformedFromSize
        }
        return (data, http)
    }

    private func mappedTransportError(_ error: Error) -> Error {
        if ProviderStatusMapping.isTimedOut(error) {
            return ProviderError.timedOut
        }
        return error
    }
}

extension ProviderError {
    static var malformedFromSize: ProviderError { .decode }
}
