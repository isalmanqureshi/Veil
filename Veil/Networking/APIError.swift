import Foundation

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case transport(Error)
    case timeout
    case decoding(Error)
    case server(statusCode: Int, message: String?)
}
