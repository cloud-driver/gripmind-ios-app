import Foundation
import Combine

@MainActor
final class HealthCheckViewModel: ObservableObject {
    @Published var statusText: String = "尚未連線"
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func checkConnection() async {
        isLoading = true
        errorMessage = nil
        statusText = "連線中..."

        do {
            let response = try await APIClient.shared.checkHealth()
            statusText = "\(response.service)：\(response.status)"
        } catch {
            errorMessage = error.localizedDescription
            statusText = "連線失敗"
        }

        isLoading = false
    }
}
