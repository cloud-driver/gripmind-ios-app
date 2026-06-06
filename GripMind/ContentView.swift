import SwiftUI

struct ContentView: View {
    @AppStorage("savedDeviceId") private var savedDeviceId: String = ""

    var body: some View {
        if savedDeviceId.isEmpty {
            OnboardingView()
        } else {
            MainTabView()
        }
    }
}

#Preview {
    ContentView()
}
