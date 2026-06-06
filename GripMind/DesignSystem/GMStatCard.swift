import SwiftUI

struct GMStatCard: View {
    let title: String
    let value: String
    let unit: String
    let systemImage: String

    var body: some View {
        GMCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(GMTheme.softBlue)
                            .frame(width: 34, height: 34)

                        Image(systemName: systemImage)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(GMTheme.primary)
                    }

                    Spacer()
                }

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(GMTheme.textSecondary)

                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(value)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(GMTheme.textPrimary)
                        .minimumScaleFactor(0.7)

                    Text(unit)
                        .font(.footnote)
                        .foregroundStyle(GMTheme.textSecondary)
                }
            }
            .frame(minHeight: 120)
        }
    }
}
