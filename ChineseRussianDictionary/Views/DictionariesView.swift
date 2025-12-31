import SwiftUI

struct DictionariesView: View {
    @ObservedObject var viewModel: DictionaryViewModel
    @State private var showingAddDictionary = false
    @State private var selectedDictionary: DictionaryEntity?
    
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
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.dictionaries) { dictionary in
                            DictionaryCard(dictionary: dictionary) {
                                selectedDictionary = dictionary
                            } onToggle: {
                                viewModel.toggleDictionaryActive(dictionary)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Словари")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddDictionary = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.cyan)
                    }
                }
            }
            .sheet(isPresented: $showingAddDictionary) {
                AddDictionaryView(viewModel: viewModel)
            }
            .sheet(item: $selectedDictionary) { dictionary in
                DictionaryDetailView(dictionary: dictionary, viewModel: viewModel)
            }
        }
    }
}

struct DictionaryCard: View {
    let dictionary: DictionaryEntity
    let onTap: () -> Void
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            GlassCard {
                HStack(spacing: 16) {
                    Circle()
                        .fill(colorFromString(dictionary.color ?? "cyan"))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "book.closed")
                                .foregroundColor(.white)
                                .font(.system(size: 24))
                        )
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(dictionary.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if let description = dictionary.descriptionText, !description.isEmpty {
                            Text(description)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(2)
                        }
                        
                        Text("\(dictionary.activeWordsCount) слов")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Button(action: onToggle) {
                        Image(systemName: dictionary.isActive ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 24))
                            .foregroundColor(dictionary.isActive ? .green : .gray)
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
        }
        .buttonStyle(.plain)
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
