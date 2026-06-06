import SwiftUI

struct GMMessageCard: View {
    enum Style {
        case success
        case warning
        case error
        case info

        var color: Color {
            switch self {
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            case .info: return .blue
            }
        }

        var background: Color {
            switch self {
            case .success: return GMTheme.softGreen
            case .warning: return GMTheme.softOrange
            case .error: return GMTheme.softRed
            case .info: return GMTheme.softBlue
            }
        }

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }

    let title: String
    let message: String
    let style: Style

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: style.icon)
                .font(.title3)
                .foregroundStyle(style.color)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(style.background)
        .clipShape(RoundedRectangle(cornerRadius: GMTheme.cornerRadius))
    }
}
