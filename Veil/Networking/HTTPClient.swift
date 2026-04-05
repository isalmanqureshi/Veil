import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

final class HTTPClient {
    private let session: URLSession
    private let config: BackendConfig
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(config: BackendConfig, session: URLSession? = nil) {
        self.config = config

        if let session {
            self.session = session
        } else {
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForRequest = config.timeout
            sessionConfig.timeoutIntervalForResource = config.timeout
            self.session = URLSession(configuration: sessionConfig)
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func get<T: Decodable>(path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        let request = try buildRequest(path: path, method: .get, queryItems: queryItems, body: Optional<EmptyBody>.none)
        let (data, _) = try await perform(request)
        return try decode(T.self, from: data)
    }

    func post<T: Decodable, Body: Encodable>(path: String, body: Body) async throws -> T {
        let request = try buildRequest(path: path, method: .post, queryItems: [], body: body)
        let (data, _) = try await perform(request)
        return try decode(T.self, from: data)
    }

    func post<Body: Encodable>(path: String, body: Body) async throws {
        let request = try buildRequest(path: path, method: .post, queryItems: [], body: body)
        _ = try await perform(request)
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    private func buildRequest<Body: Encodable>(
        path: String,
        method: HTTPMethod,
        queryItems: [URLQueryItem],
        body: Body?
    ) throws -> URLRequest {
        guard var components = URLComponents(url: config.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url, timeoutInterval: config.timeout)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }

        #if DEBUG
        logRequest(request)
        #endif

        return request
    }

    private func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            #if DEBUG
            logResponse(http, data: data)
            #endif

            guard (200...299).contains(http.statusCode) else {
                throw APIError.server(statusCode: http.statusCode, message: String(data: data, encoding: .utf8))
            }

            return (data, http)
        } catch let error as APIError {
            throw error
        } catch let error as URLError where error.code == .timedOut {
            throw APIError.timeout
        } catch {
            throw APIError.transport(error)
        }
    }

    #if DEBUG
    private func logRequest(_ request: URLRequest) {
        print("➡️ [HTTP] \(request.httpMethod ?? "-") \(request.url?.absoluteString ?? "-")")
        guard let body = request.httpBody,
              let json = Self.redactedJSONObject(from: body) else { return }

        if let data = try? JSONSerialization.data(withJSONObject: json, options: [.sortedKeys]),
           let printable = String(data: data, encoding: .utf8) {
            print("➡️ body: \(printable)")
        }
    }

    private func logResponse(_ response: HTTPURLResponse, data: Data) {
        print("⬅️ [HTTP] status=\(response.statusCode) url=\(response.url?.absoluteString ?? "-")")
        _ = data
    }

    static func redactedJSONObject(from body: Data) -> [String: Any]? {
        guard var json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else { return nil }
        let sensitiveKeys: Set<String> = [
            "payloadB64",
            "previewCiphertext",
            "token",
            "password",
            "recoveryKey",
            "seed",
            "signature"
        ]
        for key in sensitiveKeys where json[key] != nil {
            json[key] = "<redacted>"
        }
        return json
    }
    #endif
}

private struct EmptyBody: Encodable {}
