import Foundation

struct DeviceProfileResponse: Codable {
    let deviceId: String
    let profile: DeviceProfile

    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case profile
    }
}

struct DeviceProfile: Codable {
    let targetWeight: Double
    let age: String?
    let gender: String?
    let condition: String?
    let method: String?
    let points: Int?

    enum CodingKeys: String, CodingKey {
        case targetWeight = "target_weight"
        case age
        case gender
        case condition
        case method
        case points
    }
}
