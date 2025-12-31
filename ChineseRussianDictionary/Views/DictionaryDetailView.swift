import SwiftUI

struct DictionaryDetailView: View {
    let dictionary: DictionaryEntity
    @ObservedObject var viewModel: DictionaryViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingEditDictionary = false
    @State private var showingAddWord = false
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
                
                VStack(spacing: 0) {
                    // Dictionary header
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Circle()
                                    .fill(colorFromString(dictionary.color ?? "cyan"))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "book.closed")
                                            .foregroundColor(.white)
                                            .font(.system(size: 28))
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(dictionary.name)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text("\(dictionary.activeWordsCount) слов")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                            }
                            
                            if let description = dictionary.descriptionText, !description.isEmpty {
                                Text(description)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(20)
                    }
                    .padding()
                    
                    // Words list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.fetchWords(for: dictionary)) { word in
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
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: { showingAddWord = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.cyan)
                        }
                        
                        Menu {
                            Button(action: { showingEditDictionary = true }) {
                                Label("Редактировать", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive, action: {
                                viewModel.deleteDictionary(dictionary)
                                dismiss()
                            }) {
                                Label("Удалить", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.cyan)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingEditDictionary) {
                EditDictionaryView(dictionary: dictionary, viewModel: viewModel)
            }
            .sheet(isPresented: $showingAddWord) {
                AddWordView(dictionary: dictionary, viewModel: viewModel)
            }
            .sheet(item: $selectedWord) { word in
                WordDetailView(word: word, viewModel: viewModel)
            }
        }
    }
    
    private func colorFromString(_ colorString: String) -> Color {
        switch colorString {
        case "cyan": return .cyan
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "green": return .green
        case "orange": return .orange
        default: return .cyan
        }
    }
}
