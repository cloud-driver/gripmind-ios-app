import Foundation

struct GripRecord: Codable, Identifiable {
    let deviceId: String
    let grip: Double
    let timestamp: String

    var id: String {
        "\(deviceId)-\(timestamp)"
    }

    var dateValue: Date? {
        Self.formatter.date(from: timestamp)
    }

    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case grip
        case timestamp
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
