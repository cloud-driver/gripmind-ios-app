import Foundation
import Combine

enum LineBindingStatus {
    case checking
    case bound
    case unbound
    case unknown

    var title: String {
        switch self {
        case .checking:
            return "檢查中"
        case .bound:
            return "已綁定"
        case .unbound:
            return "未綁定"
        case .unknown:
            return "未知"
        }
    }

    var systemImage: String {
        switch self {
        case .checking:
            return "clock"
        case .bound:
            return "checkmark.circle.fill"
        case .unbound:
            return "xmark.circle.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }
}

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var summary: GripSummaryResponse?
    @Published var lineBindingStatus: LineBindingStatus = .checking
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func loadSummary(deviceId: String) async {
        let trimmedDeviceId = deviceId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedDeviceId.isEmpty else {
            errorMessage = "尚未設定裝置 ID"
            lineBindingStatus = .unbound
            return
        }

        if isLoading {
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            summary = try await APIClient.shared.fetchSummary(deviceId: trimmedDeviceId)
        } catch APIError.cancelled {
            isLoading = false
            return
        } catch {
            if isCancelledError(error) {
                isLoading = false
                return
            }

            errorMessage = error.localizedDescription
        }

        await checkLineBinding(deviceId: trimmedDeviceId)

        isLoading = false
    }

    private func checkLineBinding(deviceId: String) async {
        let previousStatus = lineBindingStatus
        lineBindingStatus = .checking

        do {
            _ = try await APIClient.shared.fetchProfile(deviceId: deviceId)
            lineBindingStatus = .bound
        } catch APIError.cancelled {
            lineBindingStatus = previousStatus
            return
        } catch APIError.serverError(let code) {
            if code == 404 {
                lineBindingStatus = .unbound
            } else {
                lineBindingStatus = .unknown
            }
        } catch {
            if isCancelledError(error) {
                lineBindingStatus = previousStatus
                return
            }

            lineBindingStatus = .unknown
        }
    }

    private func isCancelledError(_ error: Error) -> Bool {
        if error is CancellationError {
            return true
        }

        if let urlError = error as? URLError, urlError.code == .cancelled {
            return true
        }

        if case APIError.cancelled = error {
            return true
        }

        if case APIError.unknown(let underlyingError) = error {
            if underlyingError is CancellationError {
                return true
            }

            if let urlError = underlyingError as? URLError, urlError.code == .cancelled {
                return true
            }
        }

        return false
    }
}
