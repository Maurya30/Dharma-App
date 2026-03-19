import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical.fill")
                }
                .tag(0)

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(1)

            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.horizon.fill")
                }
                .tag(2)
        }
        .tint(.dharmaGold)
    }
}

#Preview {
    ContentView()
}
