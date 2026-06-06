import SwiftUI

struct GMCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(GMTheme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(GMTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: GMTheme.cornerRadius))
    }
}
