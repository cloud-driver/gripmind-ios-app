import SwiftUI

struct SettingsView: View {
    @AppStorage("savedDeviceId") private var savedDeviceId: String = ""
    @StateObject private var viewModel = SettingsViewModel()
    @FocusState private var focusedField: Field?

    private enum Field {
        case targetWeight
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GMAppHeader(
                    title: "設定",
                    subtitle: "裝置綁定與目標握力"
                )

                ScrollView {
                    VStack(spacing: 20) {
                        deviceSection
                        targetSection

                        if let successMessage = viewModel.successMessage {
                            GMMessageCard(
                                title: "更新成功",
                                message: successMessage,
                                style: .success
                            )
                        }

                        if let errorMessage = viewModel.errorMessage {
                            GMMessageCard(
                                title: "更新失敗",
                                message: errorMessage,
                                style: .error
                            )
                        }

                        resetSection
                        GMCopyrightFooter()
                    }
                    .padding(.horizontal, GMTheme.pagePadding)
                    .padding(.bottom, GMTheme.pagePadding)
                }
                .scrollDismissesKeyboard(.interactively)
                .contentShape(Rectangle())
                .onTapGesture {
                    focusedField = nil
                }
            }
            .background(GMTheme.background)
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                }
            }
        }
    }

    private var deviceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("裝置設定")
                .font(.headline)

            Text("目前綁定裝置")
                .font(.subheadline)
                .foregroundStyle(GMTheme.textSecondary)

            Text(savedDeviceId)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(GMTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(GMTheme.innerBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding()
        .background(.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var targetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("更改目標")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("目標握力 kg")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("目標握力", text: $viewModel.targetWeightText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .targetWeight)
            }

            Button {
                focusedField = nil
                Task {
                    await viewModel.updateTarget(deviceId: savedDeviceId)
                }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("更新目標握力")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)
        }
        .padding()
        .background(.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("重新設定裝置")
                .font(.headline)

            Text("如果要更換裝置，請清除目前綁定資料，App 會回到第一次使用的綁定流程。")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button(role: .destructive) {
                savedDeviceId = ""
            } label: {
                Text("清除綁定裝置")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
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
    SettingsView()
}
