import Foundation

struct TargetUpdateResponse: Codable {
    let deviceId: String
    let targetWeight: Double
    let message: String

    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case targetWeight = "target_weight"
        case message
    }
}
