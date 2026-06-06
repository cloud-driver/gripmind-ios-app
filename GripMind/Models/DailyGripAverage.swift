import Foundation

struct DailyGripAverage: Identifiable {
    var id: Date {
        day
    }

    let day: Date
    let averageGrip: Double
    let count: Int
}
