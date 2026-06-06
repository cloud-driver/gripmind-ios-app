import SwiftUI

enum GMTheme {
    static let primary = Color.blue

    static let background = Color(.systemGroupedBackground)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let innerBackground = Color(.tertiarySystemGroupedBackground)

    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary

    static let softBlue = Color.blue.opacity(0.10)
    static let softGreen = Color.green.opacity(0.12)
    static let softOrange = Color.orange.opacity(0.12)
    static let softRed = Color.red.opacity(0.12)

    static let cornerRadius: CGFloat = 20
    static let smallCornerRadius: CGFloat = 12
    static let pagePadding: CGFloat = 20
    static let cardPadding: CGFloat = 16
}
