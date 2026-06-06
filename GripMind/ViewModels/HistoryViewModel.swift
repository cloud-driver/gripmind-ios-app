import Foundation
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var records: [GripRecord] = []
    @Published var dailyAverages: [DailyGripAverage] = []
    @Published var selectedWeekStart: Date = HistoryViewModel.startOfWeek(for: Date())

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var hasLoadedOnce = false

    var weekDailyAverages: [DailyGripAverage] {
        let end = weekEnd

        return dailyAverages.filter { point in
            point.day >= selectedWeekStart && point.day < end
        }
    }

    var weekRecords: [GripRecord] {
        let end = weekEnd

        return records.filter { record in
            guard let date = record.dateValue else {
                return false
            }

            return date >= selectedWeekStart && date < end
        }
    }

    var weekTitle: String {
        let end = Calendar.current.date(byAdding: .day, value: 6, to: selectedWeekStart) ?? selectedWeekStart

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "M/d"

        return "\(formatter.string(from: selectedWeekStart)) - \(formatter.string(from: end))"
    }

    var canMoveToNextWeek: Bool {
        selectedWeekStart < Self.startOfWeek(for: Date())
    }

    private var weekEnd: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: selectedWeekStart) ?? selectedWeekStart
    }

    func loadRecords(deviceId: String, forceRefresh: Bool = false) async {
        let trimmedDeviceId = deviceId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedDeviceId.isEmpty else {
            errorMessage = "尚未設定裝置 ID"
            return
        }

        if isLoading && !forceRefresh {
            return
        }

        isLoading = !hasLoadedOnce
        errorMessage = nil

        do {
            let response = try await APIClient.shared.fetchRecords(
                deviceId: trimmedDeviceId,
                limit: 300
            )

            let sortedRecords = response.records.sorted {
                ($0.dateValue ?? .distantPast) < ($1.dateValue ?? .distantPast)
            }

            records = sortedRecords
            dailyAverages = makeDailyAverages(from: sortedRecords)

            // 第一次載入時，預設跳到最新資料所在週
            if !hasLoadedOnce, let latestDate = sortedRecords.last?.dateValue {
                selectedWeekStart = Self.startOfWeek(for: latestDate)
            }

            hasLoadedOnce = true

        } catch APIError.cancelled {
            isLoading = false
            return
        } catch {
            if isCancelledError(error) {
                isLoading = false
                return
            }

            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func moveWeek(by value: Int) {
        guard let newWeek = Calendar.current.date(byAdding: .day, value: value * 7, to: selectedWeekStart) else {
            return
        }

        selectedWeekStart = Self.startOfWeek(for: newWeek)
    }

    func jumpToCurrentWeek() {
        selectedWeekStart = Self.startOfWeek(for: Date())
    }

    func jumpToLatestDataWeek() {
        guard let latestDate = records.last?.dateValue else {
            selectedWeekStart = Self.startOfWeek(for: Date())
            return
        }

        selectedWeekStart = Self.startOfWeek(for: latestDate)
    }

    private func makeDailyAverages(from records: [GripRecord]) -> [DailyGripAverage] {
        let calendar = Calendar.current

        let grouped = Dictionary(grouping: records) { record -> Date in
            guard let date = record.dateValue else {
                return .distantPast
            }

            return calendar.startOfDay(for: date)
        }

        return grouped
            .filter { $0.key != .distantPast }
            .map { day, records in
                let values = records.map { $0.grip }
                let average = values.reduce(0, +) / Double(values.count)

                return DailyGripAverage(
                    day: day,
                    averageGrip: average,
                    count: records.count
                )
            }
            .sorted { $0.day < $1.day }
    }

    private static func startOfWeek(for date: Date) -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // 週一作為一週開始

        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? calendar.startOfDay(for: date)
    }

    private func isCancelledError(_ error: Error) -> Bool {
        if error is CancellationError {
            return true
        }

        if let urlError = error as? URLError, urlError.code == .cancelled {
            return true
        }

        if case APIError.cancelled = error {
            return true
        }

        if case APIError.unknown(let underlyingError) = error {
            if underlyingError is CancellationError {
                return true
            }

            if let urlError = underlyingError as? URLError, urlError.code == .cancelled {
                return true
            }
        }

        return false
    }
}
