import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = DictionaryViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SearchView(viewModel: viewModel)
                .tabItem {
                    Label("Поиск", systemImage: "magnifyingglass")
                }
                .tag(0)
            
            DictionariesView(viewModel: viewModel)
                .tabItem {
                    Label("Словари", systemImage: "book.closed")
                }
                .tag(1)
            
            FavoritesView(viewModel: viewModel)
                .tabItem {
                    Label("Избранное", systemImage: "star")
                }
                .tag(2)
        }
        .accentColor(.cyan)
    }
}
