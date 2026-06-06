import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("首頁", systemImage: "house.fill")
                }

            HistoryView()
                .tabItem {
                    Label("紀錄", systemImage: "chart.line.uptrend.xyaxis")
                }

            AnalysisView()
                .tabItem {
                    Label("AI", systemImage: "sparkles")
                }

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
}
