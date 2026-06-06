import SwiftUI

struct OnboardingView: View {
    @AppStorage("savedDeviceId") private var savedDeviceId: String = ""

    @State private var deviceId: String = ""
    @State private var hasOpenedLineBinding: Bool = false
    @State private var isChecking: Bool = false
    @State private var errorMessage: String?

    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 8) {
                    Text("GripMind")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("請先綁定您的復健裝置")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("裝置 ID")
                        .font(.headline)

                    TextField("例如：device_demo_001", text: $deviceId)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button {
                        openLineBinding()
                    } label: {
                        Text("開啟 LINE 綁定")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        Task {
                            await verifyAndSaveDevice()
                        }
                    } label: {
                        if isChecking {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("我已完成綁定，進入 App")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isChecking)
                }
                .padding()
                .background(.gray.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Text("第一次使用時需要透過 LINE Login 綁定裝置。綁定完成後，App 會記住您的裝置 ID，之後不需要重複輸入。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding()
        }
        .onOpenURL { url in
            handleAppCallback(url)
        }
    }
    
    private func handleAppCallback(_ url: URL) {
        guard url.scheme == "gripmind",
              url.host == "bind-success" else {
            return
        }

        Task {
            await verifyAndSaveDevice(requireOpenedBinding: false)
        }
    }

    private func openLineBinding() {
        let trimmed = deviceId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            errorMessage = "請先輸入 device_id"
            return
        }

        var components = URLComponents(string: "https://gripmind.hasaki.idv.tw/login")
        components?.queryItems = [
            URLQueryItem(name: "device_id", value: trimmed),
            URLQueryItem(name: "client", value: "ios"),
            URLQueryItem(name: "app_callback_url", value: "gripmind://bind-success")
        ]

        guard let url = components?.url else {
            errorMessage = "LINE 綁定網址產生失敗"
            return
        }

        errorMessage = nil
        hasOpenedLineBinding = true
        openURL(url)
    }

    private func verifyAndSaveDevice(requireOpenedBinding: Bool = true) async {
        let trimmed = deviceId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            errorMessage = "請先輸入 device_id"
            return
        }

        if requireOpenedBinding && !hasOpenedLineBinding {
            errorMessage = "請先開啟 LINE 綁定頁"
            return
        }

        isChecking = true
        errorMessage = nil

        do {
            _ = try await APIClient.shared.fetchProfile(deviceId: trimmed)
            savedDeviceId = trimmed
        } catch {
            errorMessage = "尚未確認綁定成功，請完成 LINE 綁定後再試一次。錯誤：\(error.localizedDescription)"
        }

        isChecking = false
    }
}

#Preview {
    OnboardingView()
}
