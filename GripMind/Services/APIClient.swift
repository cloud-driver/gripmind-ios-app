import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError
    case cancelled
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "API URL 無效"
        case .invalidResponse:
            return "伺服器回應格式錯誤"
        case .serverError(let code):
            return "伺服器錯誤，狀態碼：\(code)"
        case .decodingError:
            return "資料解析失敗"
        case .cancelled:
            return "請求已取消"
        case .unknown(let error):
            return "未知錯誤：\(error.localizedDescription)"
        }
    }
}

final class APIClient {
    static let shared = APIClient()

    private let baseURL = "https://gripmind.hasaki.idv.tw/api/v1"

    private init() {}

    func checkHealth() async throws -> HealthResponse {
        guard let url = URL(string: "\(baseURL)/health") else {
            throw APIError.invalidURL
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard 200..<300 ~= httpResponse.statusCode else {
                throw APIError.serverError(httpResponse.statusCode)
            }

            do {
                return try JSONDecoder().decode(HealthResponse.self, from: data)
            } catch {
                throw APIError.decodingError
            }

        } catch let error as APIError {
            throw error
        } catch {
            throw mapNetworkError(error)
        }
    }

    func fetchSummary(deviceId: String) async throws -> GripSummaryResponse {
        guard let encodedDeviceId = deviceId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/devices/\(encodedDeviceId)/summary") else {
            throw APIError.invalidURL
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard 200..<300 ~= httpResponse.statusCode else {
                throw APIError.serverError(httpResponse.statusCode)
            }

            do {
                return try JSONDecoder().decode(GripSummaryResponse.self, from: data)
            } catch {
                throw APIError.decodingError
            }

        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.unknown(error)
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw APIError.cancelled
        } catch {
            throw mapNetworkError(error)
        }
    }
    
    func fetchRecords(deviceId: String, limit: Int? = nil) async throws -> GripRecordsResponse {
        guard let encodedDeviceId = deviceId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw APIError.invalidURL
        }

        var components = URLComponents(string: "\(baseURL)/devices/\(encodedDeviceId)/records")

        var queryItems: [URLQueryItem] = []

        if let limit {
            queryItems.append(URLQueryItem(name: "limit", value: "\(limit)"))
        }

        // 強制每次刷新都用不同 URL，避免 URLSession / proxy / Cloudflare 快取
        queryItems.append(URLQueryItem(name: "_refresh", value: UUID().uuidString))

        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard 200..<300 ~= httpResponse.statusCode else {
                throw APIError.serverError(httpResponse.statusCode)
            }

            do {
                return try JSONDecoder().decode(GripRecordsResponse.self, from: data)
            } catch {
                throw APIError.decodingError
            }

        } catch {
            throw mapNetworkError(error)
        }
    }
    
    func updateTarget(deviceId: String, targetWeight: Double) async throws -> TargetUpdateResponse {
        guard let encodedDeviceId = deviceId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/devices/\(encodedDeviceId)/target") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = [
            "target_weight": targetWeight
        ]

        request.httpBody = try JSONEncoder().encode(body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard 200..<300 ~= httpResponse.statusCode else {
                throw APIError.serverError(httpResponse.statusCode)
            }

            do {
                return try JSONDecoder().decode(TargetUpdateResponse.self, from: data)
            } catch {
                throw APIError.decodingError
            }

        } catch let error as APIError {
            throw error
        } catch {
            throw mapNetworkError(error)
        }
    }
    
    func fetchProfile(deviceId: String) async throws -> DeviceProfileResponse {
        guard let encodedDeviceId = deviceId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/devices/\(encodedDeviceId)/profile") else {
            throw APIError.invalidURL
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard 200..<300 ~= httpResponse.statusCode else {
                throw APIError.serverError(httpResponse.statusCode)
            }

            do {
                return try JSONDecoder().decode(DeviceProfileResponse.self, from: data)
            } catch {
                throw APIError.decodingError
            }

        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.unknown(error)
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw APIError.cancelled
        } catch {
            throw mapNetworkError(error)
        }
    }
    
    func fetchAnalysis(deviceId: String) async throws -> AnalysisResponse {
        guard let encodedDeviceId = deviceId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/devices/\(encodedDeviceId)/analysis") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard 200..<300 ~= httpResponse.statusCode else {
                throw APIError.serverError(httpResponse.statusCode)
            }

            do {
                return try JSONDecoder().decode(AnalysisResponse.self, from: data)
            } catch {
                throw APIError.decodingError
            }

        } catch let error as APIError {
            throw error
        } catch {
            throw mapNetworkError(error)
        }
    }
    
    private func mapNetworkError(_ error: Error) -> APIError {
        if error is CancellationError {
            return .cancelled
        }

        if let urlError = error as? URLError, urlError.code == .cancelled {
            return .cancelled
        }

        if let apiError = error as? APIError {
            return apiError
        }

        return .unknown(error)
    }
}
