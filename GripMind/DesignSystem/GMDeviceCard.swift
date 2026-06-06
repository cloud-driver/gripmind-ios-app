import SwiftUI

struct GMDeviceCard: View {
    let deviceId: String

    var body: some View {
        GMCard {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(GMTheme.softBlue)
                        .frame(width: 44, height: 44)

                    Image(systemName: "sensor.tag.radiowaves.forward")
                        .foregroundStyle(GMTheme.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("目前綁定裝置")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(deviceId.isEmpty ? "尚未綁定" : deviceId)
                        .font(.headline)
                }

                Spacer()
            }
        }
    }
}
