import SwiftUI

struct DashboardView: View {
    @AppStorage("savedDeviceId") private var savedDeviceId: String = ""
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GMAppHeader(
                    title: "GripMind",
                    subtitle: "智慧握力復健紀錄",
                    trailing: AnyView(lineBindingBadge)
                )

                ScrollView {
                    VStack(spacing: 20) {
                        deviceCard

                        if viewModel.isLoading && viewModel.summary == nil {
                            ProgressView("讀取資料中...")
                                .padding()
                        }

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .padding()
                        }

                        if let summary = viewModel.summary {
                            summarySection(summary)
                        }
                    }
                    .padding(.horizontal, GMTheme.pagePadding)
                    .padding(.bottom, GMTheme.pagePadding)
                }
                .refreshable {
                    await viewModel.loadSummary(deviceId: savedDeviceId)
                }
            }
            .background(GMTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .task {
            await viewModel.loadSummary(deviceId: savedDeviceId)
        }
    }
    
    private var lineBindingBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: viewModel.lineBindingStatus.systemImage)

            Text(viewModel.lineBindingStatus.title)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(lineBindingColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(lineBindingColor.opacity(0.12))
        .clipShape(Capsule())
    }
    
    private var lineBindingColor: Color {
        switch viewModel.lineBindingStatus {
        case .checking:
            return .orange
        case .bound:
            return .green
        case .unbound:
            return .red
        case .unknown:
            return .gray
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

    private func summarySection(_ summary: GripSummaryResponse) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                GMStatCard(
                    title: "今日次數",
                    value: "\(summary.today.count)",
                    unit: "次",
                    systemImage: "number.circle.fill"
                )

                GMStatCard(
                    title: "目標握力",
                    value: String(format: "%.1f", summary.targetWeight),
                    unit: "kg",
                    systemImage: "target"
                )
            }

            HStack(spacing: 12) {
                GMStatCard(
                    title: "今日最高",
                    value: summary.today.maxGrip.map { String(format: "%.1f", $0) } ?? "--",
                    unit: "kg",
                    systemImage: "arrow.up.circle.fill"
                )

                GMStatCard(
                    title: "今日平均",
                    value: summary.today.averageGrip.map { String(format: "%.1f", $0) } ?? "--",
                    unit: "kg",
                    systemImage: "chart.bar.fill"
                )
            }

            goalStatusCard(summary)

            if let latest = summary.latestRecord {
                latestRecordCard(latest)
            }
        }
    }

    private func goalStatusCard(_ summary: GripSummaryResponse) -> some View {
        GMMessageCard(
            title: "今日目標狀態",
            message: summary.today.goalReached
                ? "已達標，繼續保持。"
                : "尚未達標，今天還可以再訓練一次。",
            style: summary.today.goalReached ? .success : .warning
        )
    }

    private func latestRecordCard(_ record: GripRecord) -> some View {
        GMCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("最近一次紀錄")
                        .font(.headline)

                    Spacer()

                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(GMTheme.primary)
                }

                Text("\(String(format: "%.1f", record.grip)) kg")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(record.timestamp)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    DashboardView()
}
