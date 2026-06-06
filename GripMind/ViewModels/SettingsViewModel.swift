import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var targetWeightText: String = "4.0"
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    func updateTarget(deviceId: String) async {
        let trimmedDeviceId = deviceId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedDeviceId.isEmpty else {
            errorMessage = "尚未設定裝置 ID"
            successMessage = nil
            return
        }

        guard let targetWeight = Double(targetWeightText), targetWeight > 0 else {
            errorMessage = "目標握力必須是大於 0 的數字"
            successMessage = nil
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
            let response = try await APIClient.shared.updateTarget(
                deviceId: trimmedDeviceId,
                targetWeight: targetWeight
            )

            successMessage = "目標已更新為 \(String(format: "%.1f", response.targetWeight)) kg"
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
