import SwiftUI

struct AddWordView: View {
    let dictionary: DictionaryEntity
    @ObservedObject var viewModel: DictionaryViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var chinese = ""
    @State private var pinyin = ""
    @State private var russian = ""
    @State private var hskLevel: Int = 0
    
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
                        // Preview
                        if !chinese.isEmpty || !pinyin.isEmpty || !russian.isEmpty {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(chinese.isEmpty ? "汉字" : chinese)
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(pinyin.isEmpty ? "pinyin" : pinyin)
                                        .font(.system(size: 16))
                                        .foregroundColor(.cyan.opacity(0.9))
                                    
                                    if !russian.isEmpty {
                                        Divider()
                                            .background(Color.white.opacity(0.3))
                                        
                                        Text(russian)
                                            .font(.system(size: 20))
                                            .foregroundColor(.white.opacity(0.95))
                                    }
                                    
                                    if hskLevel > 0 {
                                        Text("HSK \(hskLevel)")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(Color.purple.opacity(0.6))
                                            )
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(20)
                            }
                        }
                        
                        // Form
                        VStack(spacing: 16) {
                            GlassTextField(placeholder: "汉字 (китайские иероглифы)", text: $chinese, systemImage: "textformat.abc")
                            
                            GlassTextField(placeholder: "Pinyin (пиньинь)", text: $pinyin, systemImage: "textformat")
                            
                            GlassTextField(placeholder: "Перевод на русский", text: $russian, systemImage: "character.book.closed")
                            
                            // HSK Level picker
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Уровень HSK")
                                    .foregroundColor(.white.opacity(0.9))
                                    .font(.system(size: 16, weight: .medium))
                                    .padding(.horizontal, 16)
                                
                                HStack(spacing: 8) {
                                    ForEach(0...6, id: \.self) { level in
                                        Button(action: { hskLevel = level }) {
                                            Text(level == 0 ? "—" : "\(level)")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(hskLevel == level ? .white : .white.opacity(0.6))
                                                .frame(width: 44, height: 44)
                                                .background(
                                                    Circle()
                                                        .fill(hskLevel == level ? Color.purple.opacity(0.6) : Color.clear)
                                                        .overlay(
                                                            Circle()
                                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                                        )
                                                )
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        GlassButton("Добавить слово", systemImage: "plus.circle.fill", color: .cyan) {
                            viewModel.createWord(
                                chinese: chinese,
                                pinyin: pinyin,
                                russian: russian,
                                hskLevel: Int16(hskLevel),
                                dictionary: dictionary
                            )
                            dismiss()
                        }
                        .disabled(chinese.isEmpty || pinyin.isEmpty || russian.isEmpty)
                        .opacity(chinese.isEmpty || pinyin.isEmpty || russian.isEmpty ? 0.5 : 1)
                    }
                    .padding()
                }
            }
            .navigationTitle("Новое слово")
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
