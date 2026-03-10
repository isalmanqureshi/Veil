import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum HTTPClientError: Error {
    case invalidResponse
    case statusCode(Int, Data)
}

final class HTTPClient {
    private let session: URLSession
    private let config: BackendConfig
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(config: BackendConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func request<T: Decodable, Body: Encodable>(
        path: String,
        method: HTTPMethod,
        body: Body? = nil,
        headers: [String: String] = [:]
    ) async throws -> T {
        let request = try buildRequest(path: path, method: method, body: body, headers: headers)
        let (data, response) = try await perform(request)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            #if DEBUG
            debugPrint("⬇️ decode error:", error)
            #endif
            throw error
        }
    }

    func send<Body: Encodable>(
        path: String,
        method: HTTPMethod,
        body: Body? = nil,
        headers: [String: String] = [:]
    ) async throws {
        let request = try buildRequest(path: path, method: method, body: body, headers: headers)
        _ = try await perform(request)
    }

    private func buildRequest<Body: Encodable>(
        path: String,
        method: HTTPMethod,
        body: Body?,
        headers: [String: String]
    ) throws -> URLRequest {
        let url = config.baseURL.appending(path: path)
        var request = URLRequest(url: url, timeoutInterval: config.timeout)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

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
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw HTTPClientError.invalidResponse
        }

        #if DEBUG
        logResponse(http, data: data)
        #endif

        guard (200...299).contains(http.statusCode) else {
            throw HTTPClientError.statusCode(http.statusCode, data)
        }

        return (data, http)
    }

    #if DEBUG
    private func logRequest(_ request: URLRequest) {
        let body = request.httpBody.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        debugPrint("➡️ [HTTP] \(request.httpMethod ?? "-") \(request.url?.absoluteString ?? "-")")
        if !body.isEmpty {
            debugPrint("➡️ body:", body)
        }
    }

    private func logResponse(_ response: HTTPURLResponse, data: Data) {
        let body = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
        debugPrint("⬅️ [HTTP] status=\(response.statusCode) url=\(response.url?.absoluteString ?? "-")")
        if !body.isEmpty {
            debugPrint("⬅️ body:", body)
        }
    }
    #endif
}
