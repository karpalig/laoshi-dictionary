import SwiftUI

struct AddExampleView: View {
    let word: WordEntity
    @ObservedObject var viewModel: DictionaryViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var chinese = ""
    @State private var pinyin = ""
    @State private var russian = ""
    
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
                    VStack(spacing: 24) {
                        // Context
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Добавление примера к слову:")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text(word.chinese)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text(word.pinyin)
                                    .font(.system(size: 14))
                                    .foregroundColor(.cyan.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                        }
                        
                        // Preview
                        if !chinese.isEmpty || !pinyin.isEmpty || !russian.isEmpty {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    Image(systemName: "text.quote")
                                        .font(.system(size: 14))
                                        .foregroundColor(.cyan.opacity(0.7))
                                    
                                    Text(chinese.isEmpty ? "Предложение на китайском..." : chinese)
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                    
                                    Text(pinyin.isEmpty ? "Pinyin предложения..." : pinyin)
                                        .font(.system(size: 14))
                                        .foregroundColor(.cyan.opacity(0.8))
                                    
                                    if !russian.isEmpty {
                                        Text(russian)
                                            .font(.system(size: 16))
                                            .foregroundColor(.white.opacity(0.85))
                                    }
                                }
                                .padding(16)
                            }
                        }
                        
                        // Form
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "textformat.abc")
                                        .foregroundColor(.cyan.opacity(0.7))
                                        .font(.system(size: 18))
                                    
                                    Text("Предложение на китайском")
                                        .foregroundColor(.white.opacity(0.7))
                                        .font(.system(size: 16))
                                }
                                .padding(.horizontal, 16)
                                
                                TextEditor(text: $chinese)
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                                    .scrollContentBackground(.hidden)
                                    .frame(height: 80)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 15)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                            }
                            
                            GlassTextField(placeholder: "Pinyin предложения", text: $pinyin, systemImage: "textformat")
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "character.book.closed")
                                        .foregroundColor(.cyan.opacity(0.7))
                                        .font(.system(size: 18))
                                    
                                    Text("Перевод на русский")
                                        .foregroundColor(.white.opacity(0.7))
                                        .font(.system(size: 16))
                                }
                                .padding(.horizontal, 16)
                                
                                TextEditor(text: $russian)
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                                    .scrollContentBackground(.hidden)
                                    .frame(height: 80)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 15)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                            }
                        }
                        
                        GlassButton("Добавить пример", systemImage: "plus.circle.fill", color: .cyan) {
                            viewModel.createExample(
                                for: word,
                                chinese: chinese,
                                pinyin: pinyin,
                                russian: russian
                            )
                            dismiss()
                        }
                        .disabled(chinese.isEmpty || pinyin.isEmpty || russian.isEmpty)
                        .opacity(chinese.isEmpty || pinyin.isEmpty || russian.isEmpty ? 0.5 : 1)
                    }
                    .padding()
                }
            }
            .navigationTitle("Новый пример")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
        }
    }
}
