import SwiftUI
import Charts

struct HistoryChartView: View {
    let points: [DailyGripAverage]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("握力趨勢")
                .font(.headline)
                .foregroundStyle(GMTheme.textPrimary)

            if points.isEmpty {
                Text("這週還沒有可顯示的握力資料")
                    .font(.subheadline)
                    .foregroundStyle(GMTheme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 220)
            } else {
                Chart(points) { point in
                    LineMark(
                        x: .value("日期", point.day, unit: .day),
                        y: .value("平均握力", point.averageGrip)
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("日期", point.day, unit: .day),
                        y: .value("平均握力", point.averageGrip)
                    )
                }
                .frame(height: 260)
                .chartYAxisLabel("kg")
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.defaultDigits).day())
                    }
                }
            }
        }
        .padding(GMTheme.cardPadding)
        .background(GMTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: GMTheme.cornerRadius))
    }
}

#Preview {
    HistoryChartView(points: [
        DailyGripAverage(day: Date(), averageGrip: 3.2, count: 3)
    ])
}
