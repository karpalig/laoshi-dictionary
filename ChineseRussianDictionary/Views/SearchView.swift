import SwiftUI

struct SearchView: View {
    @ObservedObject var viewModel: DictionaryViewModel
    @State private var showingAddWord = false
    @State private var selectedWord: WordEntity?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color(red: 0.1, green: 0.05, blue: 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Search bar
                    GlassTextField(placeholder: "汉字, pinyin, русский...", text: $viewModel.searchText, systemImage: "magnifyingglass")
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    // Results
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if viewModel.searchText.isEmpty {
                                // Recent words
                                if !viewModel.allWords.isEmpty {
                                    sectionHeader("Недавние слова")
                                    
                                    ForEach(Array(viewModel.allWords.prefix(10))) { word in
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
                                } else {
                                    emptyState
                                }
                            } else {
                                // Search results
                                if viewModel.searchResults.isEmpty {
                                    noResultsState
                                } else {
                                    sectionHeader("Результаты поиска (\(viewModel.searchResults.count))")
                                    
                                    ForEach(viewModel.searchResults) { word in
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
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Поиск")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedWord) { word in
                WordDetailView(word: word, viewModel: viewModel)
            }
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
            Spacer()
        }
        .padding(.top, 10)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.cyan.opacity(0.5))
            
            Text("Словарь пуст")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            Text("Добавьте слова в словарь")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.6))
            
            Button(action: { viewModel.createSampleData() }) {
                Text("Загрузить примеры")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.cyan)
            }
        }
        .padding(.top, 100)
    }
    
    private var noResultsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.4))
            
            Text("Ничего не найдено")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text("Попробуйте другой запрос")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.top, 60)
    }
}
