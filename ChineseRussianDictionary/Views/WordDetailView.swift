import SwiftUI

struct WordDetailView: View {
    let word: WordEntity
    @ObservedObject var viewModel: DictionaryViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingEditWord = false
    @State private var showingAddExample = false
    @State private var editingExample: ExampleEntity?
    
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
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Word main card
                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text(word.chinese)
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Button(action: { viewModel.toggleFavorite(word) }) {
                                        Image(systemName: word.isFavorite ? "star.fill" : "star")
                                            .font(.system(size: 24))
                                            .foregroundColor(word.isFavorite ? .yellow : .gray)
                                    }
                                }
                                
                                Text(word.pinyin)
                                    .font(.system(size: 20))
                                    .foregroundColor(.cyan.opacity(0.9))
                                
                                Divider()
                                    .background(Color.white.opacity(0.3))
                                
                                Text(word.russian)
                                    .font(.system(size: 24))
                                    .foregroundColor(.white.opacity(0.95))
                                
                                HStack {
                                    if word.hskLevel > 0 {
                                        Text("HSK \(word.hskLevel)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(Color.purple.opacity(0.6))
                                            )
                                    }
                                    
                                    Spacer()
                                    
                                    if let dict = word.dictionary {
                                        Text(dict.name)
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
                            }
                            .padding(20)
                        }
                        
                        // Examples section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Примеры использования")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Spacer()
                                
                                Button(action: { showingAddExample = true }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.cyan)
                                }
                            }
                            
                            if word.examplesArray.isEmpty {
                                GlassCard {
                                    VStack(spacing: 8) {
                                        Image(systemName: "text.quote")
                                            .font(.system(size: 30))
                                            .foregroundColor(.white.opacity(0.4))
                                        
                                        Text("Нет примеров")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(32)
                                }
                            } else {
                                ForEach(word.examplesArray) { example in
                                    ExampleCard(example: example) {
                                        editingExample = example
                                    } onDelete: {
                                        viewModel.deleteExample(example)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
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
                    Menu {
                        Button(action: { showingEditWord = true }) {
                            Label("Редактировать", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: {
                            viewModel.deleteWord(word)
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
            .sheet(isPresented: $showingEditWord) {
                EditWordView(word: word, viewModel: viewModel)
            }
            .sheet(isPresented: $showingAddExample) {
                AddExampleView(word: word, viewModel: viewModel)
            }
            .sheet(item: $editingExample) { example in
                EditExampleView(example: example, viewModel: viewModel)
            }
        }
    }
}

struct ExampleCard: View {
    let example: ExampleEntity
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "text.quote")
                        .font(.system(size: 14))
                        .foregroundColor(.cyan.opacity(0.7))
                    
                    Spacer()
                    
                    Menu {
                        Button(action: onEdit) {
                            Label("Редактировать", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: onDelete) {
                            Label("Удалить", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Text(example.chineseSentence)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                
                Text(example.pinyinSentence)
                    .font(.system(size: 14))
                    .foregroundColor(.cyan.opacity(0.8))
                
                Text(example.russianTranslation)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(16)
        }
    }
}
