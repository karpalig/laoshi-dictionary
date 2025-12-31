import SwiftUI

struct FavoritesView: View {
    @ObservedObject var viewModel: DictionaryViewModel
    @State private var selectedWord: WordEntity?
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color(red: 0.1, green: 0.05, blue: 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if viewModel.favoriteWords.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.favoriteWords) { word in
                                WordCard(
                                    word: word,
                                    onTap: {
                                        selectedWord = word
                                        viewModel.updateLastAccessed(word)
                                    },
                                    onFavorite: {
                                        viewModel.toggleFavorite(word)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Избранное")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedWord) { word in
                WordDetailView(word: word, viewModel: viewModel)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "star")
                .font(.system(size: 60))
                .foregroundColor(.yellow.opacity(0.5))
            
            Text("Нет избранных слов")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            Text("Добавьте слова в избранное")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}
