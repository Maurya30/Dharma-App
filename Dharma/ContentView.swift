import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.horizon.fill")
                }
                .tag(0)

            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical.fill")
                }
                .tag(1)

            JourneyView()
                .tabItem {
                    Label("Journey", systemImage: "figure.walk")
                }
                .tag(2)

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(3)
        }
        .tint(.dharmaGold)
    }
}

#Preview {
    ContentView()
}
