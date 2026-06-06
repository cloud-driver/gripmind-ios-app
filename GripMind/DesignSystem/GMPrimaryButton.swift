import SwiftUI

struct GMPrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(GMTheme.primary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .disabled(isLoading)
        .opacity(isLoading ? 0.75 : 1)
    }
}
