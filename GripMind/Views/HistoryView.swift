import SwiftUI

struct HistoryView: View {
    @AppStorage("savedDeviceId") private var savedDeviceId: String = ""
    @StateObject private var viewModel = HistoryViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GMAppHeader(
                    title: "歷史紀錄",
                    subtitle: "每週握力趨勢與訓練紀錄"
                )

                ScrollView {
                    VStack(spacing: 20) {
                        deviceCard
                        weekSelector

                        if viewModel.isLoading && viewModel.records.isEmpty {
                            ProgressView("讀取紀錄中...")
                                .padding()
                        }

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .padding()
                        }

                        HistoryChartView(points: viewModel.weekDailyAverages)
                        RecordsListView(records: viewModel.weekRecords)
                    }
                    .padding(.horizontal, GMTheme.pagePadding)
                    .padding(.bottom, GMTheme.pagePadding)
                }
                .refreshable {
                    await viewModel.loadRecords(
                        deviceId: savedDeviceId,
                        forceRefresh: true
                    )
                }
            }
            .background(GMTheme.background)
            .toolbar(.hidden, for: .navigationBar)
        }
        .task(id: savedDeviceId) {
            await viewModel.loadRecords(
                deviceId: savedDeviceId,
                forceRefresh: true
            )
        }
    }
    
    private var weekSelector: some View {
        GMCard {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Button {
                        viewModel.moveWeek(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(GMTheme.primary)
                            .clipShape(Circle())
                    }

                    Spacer()

                    VStack(spacing: 4) {
                        Text("目前週次")
                            .font(.caption)
                            .foregroundStyle(GMTheme.textSecondary)

                        Text(viewModel.weekTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(GMTheme.textPrimary)
                    }

                    Spacer()

                    Button {
                        viewModel.moveWeek(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(viewModel.canMoveToNextWeek ? GMTheme.primary : Color.gray.opacity(0.35))
                            .clipShape(Circle())
                    }
                    .disabled(!viewModel.canMoveToNextWeek)
                }

                Button {
                    viewModel.jumpToLatestDataWeek()
                } label: {
                    Text("跳到最新資料週")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                }
                .buttonStyle(.borderedProminent)
            }
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
}

#Preview {
    HistoryView()
}
