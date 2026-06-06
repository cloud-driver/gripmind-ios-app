import SwiftUI

struct RecordsListView: View {
    let records: [GripRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("歷史紀錄")
                .font(.headline)

            if records.isEmpty {
                Text("目前沒有握力紀錄")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 10) {
                    ForEach(records.reversed()) { record in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.timestamp)
                                    .font(.caption)
                                    .foregroundStyle(GMTheme.textSecondary)

                                Text("裝置：\(record.deviceId)")
                                    .font(.caption2)
                                    .foregroundStyle(GMTheme.textSecondary)
                            }

                            Spacer()

                            Text(String(format: "%.1f kg", record.grip))
                                .font(.headline)
                                .foregroundStyle(GMTheme.textPrimary)
                        }
                        .padding()
                        .background(GMTheme.innerBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding(GMTheme.pagePadding)
        .background(GMTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    RecordsListView(records: [
        GripRecord(deviceId: "device_demo_001", grip: 2.3, timestamp: "20260605 23:55:10"),
        GripRecord(deviceId: "device_demo_001", grip: 3.1, timestamp: "20260606 09:30:00")
    ])
}
