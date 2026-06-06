import Foundation

struct GripRecordsResponse: Codable {
    let deviceId: String
    let count: Int
    let records: [GripRecord]

    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case count
        case records
    }
}
