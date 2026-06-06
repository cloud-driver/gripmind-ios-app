import SwiftUI

struct GMAppHeader: View {
    let title: String
    var subtitle: String? = nil
    var trailing: AnyView? = nil

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(GMTheme.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(GMTheme.textSecondary)
                }
            }

            Spacer()

            if let trailing {
                trailing
            }
        }
        .padding(.horizontal, GMTheme.pagePadding)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(GMTheme.background)
    }
}
