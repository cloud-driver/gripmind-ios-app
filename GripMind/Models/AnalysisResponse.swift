import Foundation

struct AnalysisResponse: Codable {
    let deviceId: String
    let suggestion: String
    let disclaimer: String?

    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case suggestion
        case disclaimer
    }
}
