import SwiftUI

struct AnalysisView: View {
    @AppStorage("savedDeviceId") private var savedDeviceId: String = ""
    @StateObject private var viewModel = AnalysisViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GMAppHeader(
                    title: "AI 訓練回饋",
                    subtitle: "根據近期握力紀錄產生輔助建議"
                )

                ScrollView {
                    VStack(spacing: 20) {
                        deviceCard
                        introCard

                        GMPrimaryButton(
                            title: "產生 AI 訓練回饋",
                            isLoading: viewModel.isLoading
                        ) {
                            Task {
                                await viewModel.loadAnalysis(deviceId: savedDeviceId)
                            }
                        }

                        if let errorMessage = viewModel.errorMessage {
                            GMMessageCard(
                                title: "產生失敗",
                                message: errorMessage,
                                style: .error
                            )
                        }

                        if let suggestion = viewModel.suggestion {
                            suggestionCard(suggestion)
                        }

                        if let disclaimer = viewModel.disclaimer {
                            disclaimerCard(disclaimer)
                        }
                    }
                    .padding(.horizontal, GMTheme.pagePadding)
                    .padding(.bottom, GMTheme.pagePadding)
                }
            }
            .background(GMTheme.background)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var deviceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("目前裝置")
                .font(.headline)

            Text(savedDeviceId)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("訓練回饋說明")
                .font(.headline)

            Text("系統會根據近期握力紀錄、目標握力與使用者資料，產生簡短訓練回饋。此功能僅作為復健訓練紀錄輔助，不作為醫療診斷。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func suggestionCard(_ suggestion: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.blue)

                Text("AI 訓練回饋")
                    .font(.headline)
            }

            Text(suggestion)
                .font(.body)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func disclaimerCard(_ disclaimer: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("注意事項")
                .font(.headline)

            Text(disclaimer)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func messageCard(title: String, message: String, systemImage: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    AnalysisView()
}
