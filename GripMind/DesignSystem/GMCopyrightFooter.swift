import SwiftUI

struct GMCopyrightFooter: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("GripMind iOS Prototype")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(GMTheme.textSecondary)

            Text("© 2026 Justus Cheng. Open source on GitHub.")
                .font(.caption2)
                .foregroundStyle(GMTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .padding(.bottom, 24)
    }
}
