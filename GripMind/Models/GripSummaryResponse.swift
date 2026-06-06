import Foundation

struct GripSummaryResponse: Codable {
    let deviceId: String
    let targetWeight: Double
    let latestRecord: GripRecord?
    let today: TodaySummary
    let totalRecords: Int

    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case targetWeight = "target_weight"
        case latestRecord = "latest_record"
        case today
        case totalRecords = "total_records"
    }
}

struct TodaySummary: Codable {
    let count: Int
    let maxGrip: Double?
    let averageGrip: Double?
    let goalReached: Bool

    enum CodingKeys: String, CodingKey {
        case count
        case maxGrip = "max_grip"
        case averageGrip = "average_grip"
        case goalReached = "goal_reached"
    }
}
