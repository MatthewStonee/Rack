import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Programs", systemImage: "list.bullet.clipboard.fill") {
                ProgramsView()
            }
            Tab("Progress", systemImage: "chart.line.uptrend.xyaxis") {
                ProgressTabView()
            }
        }
        .tint(.blue)
        .background(
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.06, blue: 0.18), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

#Preview {
    ContentView()
}
