//
//  GeminiClient.swift
//  Titan
//
//  Created by Steve Simkins on 12/20/25.
//

import Network
import Foundation

// MARK: - Response Types

struct GeminiResponse {
    let statusCode: Int
    let meta: String
    let body: Data?

    var statusCategory: StatusCategory {
        StatusCategory(rawValue: statusCode / 10) ?? .permanentFailure
    }

    var bodyText: String? {
        guard let body else { return nil }
        return String(data: body, encoding: .utf8)
    }

    enum StatusCategory: Int {
        case input = 1
        case success = 2
        case redirect = 3
        case temporaryFailure = 4
        case permanentFailure = 5
        case clientCertificate = 6
    }
}

enum GeminiError: LocalizedError {
    case invalidResponse
    case invalidURL
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from server"
        case .invalidURL: return "Invalid URL"
        case .cancelled: return "Request cancelled"
        }
    }
}

// MARK: - Client

class GeminiClient {
    let rejectUnauthorized: Bool
    
    init(rejectUnauthorized: Bool = true) {
        self.rejectUnauthorized = rejectUnauthorized
    }
    
    func connect(
        hostname: String,
        port: Int = 1965,
        urlString: String
    ) async throws -> GeminiResponse {
        let host = NWEndpoint.Host(hostname)
        let port = NWEndpoint.Port(integerLiteral: UInt16(port))

        let tlsOptions = NWProtocolTLS.Options()
        let rejectUnauthorized = self.rejectUnauthorized  // Capture the value, not self

        sec_protocol_options_set_verify_block(
            tlsOptions.securityProtocolOptions,
            { _, trust, verify_complete in
                if rejectUnauthorized {
                    var error: CFError?
                    let secTrust = sec_trust_copy_ref(trust).takeRetainedValue()
                    let result = SecTrustEvaluateWithError(secTrust, &error)
                    verify_complete(result)
                } else {
                    verify_complete(true)
                }
            },
            DispatchQueue.main
        )
        let parameters = NWParameters(tls: tlsOptions)
        let connection = NWConnection(host: host, port: port, using: parameters)
        let state = ConnectionState()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GeminiResponse, Error>) in
                connection.stateUpdateHandler = { connectionState in
                    switch connectionState {
                    case .ready:
                        // Check for cancellation before sending request
                        if Task.isCancelled {
                            connection.cancel()
                            if !state.continuationResumed {
                                state.continuationResumed = true
                                continuation.resume(throwing: GeminiError.cancelled)
                            }
                            return
                        }

                        print("✓ TLS connection established\n")
                        let request = urlString + "\r\n"
                        print("📤 Request: \(request.trimmingCharacters(in: .whitespacesAndNewlines))")

                        if let requestData = request.data(using: .utf8) {
                            connection.send(content: requestData, completion: .idempotent)
                        }

                        self.receiveData(connection: connection, state: state)

                    case .failed(let error):
                        print("❌ Error: \(error)")
                        connection.cancel()
                        if !state.continuationResumed {
                            state.continuationResumed = true
                            continuation.resume(throwing: error)
                        }

                    case .cancelled:
                        if !state.continuationResumed {
                            state.continuationResumed = true
                            // Check if this was a user-initiated cancellation
                            if state.wasCancelled {
                                print("✓ Request cancelled\n")
                                continuation.resume(throwing: GeminiError.cancelled)
                            } else {
                                print("✓ Connection closed by server\n")
                                do {
                                    let response = try self.parseResponse(state.responseData)
                                    continuation.resume(returning: response)
                                } catch {
                                    continuation.resume(throwing: error)
                                }
                            }
                        }

                    default:
                        break
                    }
                }

                connection.start(queue: .global())
            }
        } onCancel: {
            state.wasCancelled = true
            connection.cancel()
        }
    }
    
    private func receiveData(connection: NWConnection, state: ConnectionState) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                state.chunks.append(data)
            }

            if isComplete {
                connection.cancel()
            } else if error == nil {
                self.receiveData(connection: connection, state: state)
            } else if let error = error {
                print("❌ Receive error: \(error)")
                connection.cancel()
            }
        }
    }

    private func parseResponse(_ data: Data) throws -> GeminiResponse {
        // Find the first CRLF which separates header from body
        let crlf = Data([0x0D, 0x0A]) // \r\n
        guard let crlfRange = data.range(of: crlf) else {
            throw GeminiError.invalidResponse
        }

        let headerData = data[..<crlfRange.lowerBound]
        guard let headerString = String(data: headerData, encoding: .utf8) else {
            throw GeminiError.invalidResponse
        }

        // Parse status code (first 2 characters)
        guard headerString.count >= 2,
              let statusCode = Int(headerString.prefix(2)) else {
            throw GeminiError.invalidResponse
        }

        // Meta is everything after status code and space
        let meta: String
        if headerString.count > 3 {
            meta = String(headerString.dropFirst(3))
        } else {
            meta = ""
        }

        // Body is everything after the CRLF
        let bodyStartIndex = crlfRange.upperBound
        let body: Data? = bodyStartIndex < data.endIndex ? Data(data[bodyStartIndex...]) : nil

        print("📥 Status: \(statusCode), Meta: \(meta)")

        return GeminiResponse(statusCode: statusCode, meta: meta, body: body)
    }
    
    // Helper class to manage connection state
    private class ConnectionState: @unchecked Sendable {
        var chunks: [Data] = []
        var continuationResumed = false
        var wasCancelled = false

        var responseData: Data {
            chunks.reduce(Data(), +)
        }
    }
}
