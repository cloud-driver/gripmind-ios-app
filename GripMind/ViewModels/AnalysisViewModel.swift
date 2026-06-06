import Foundation
import Combine

@MainActor
final class AnalysisViewModel: ObservableObject {
    @Published var suggestion: String?
    @Published var disclaimer: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func loadAnalysis(deviceId: String) async {
        let trimmedDeviceId = deviceId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedDeviceId.isEmpty else {
            errorMessage = "尚未設定裝置 ID"
            return
        }

        isLoading = true
        errorMessage = nil
        suggestion = nil
        disclaimer = nil

        do {
            let response = try await APIClient.shared.fetchAnalysis(deviceId: trimmedDeviceId)
            suggestion = response.suggestion
            disclaimer = response.disclaimer
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
