import SwiftUI

struct AddDictionaryView: View {
    @ObservedObject var viewModel: DictionaryViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedColor = "cyan"
    
    let colors = ["cyan", "blue", "purple", "pink", "green", "orange"]
    
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
                        GlassCard {
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(colorFromString(selectedColor))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "book.closed")
                                            .foregroundColor(.white)
                                            .font(.system(size: 28))
                                    )
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(name.isEmpty ? "Название словаря" : name)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text(description.isEmpty ? "Описание" : description)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                            }
                            .padding(20)
                        }
                        
                        // Form
                        VStack(spacing: 16) {
                            GlassTextField(placeholder: "Название словаря", text: $name, systemImage: "book")
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "text.alignleft")
                                        .foregroundColor(.cyan.opacity(0.7))
                                        .font(.system(size: 18))
                                    
                                    Text("Описание")
                                        .foregroundColor(.white.opacity(0.7))
                                        .font(.system(size: 16))
                                }
                                .padding(.horizontal, 16)
                                
                                TextEditor(text: $description)
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                                    .scrollContentBackground(.hidden)
                                    .frame(height: 100)
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
                            
                            // Color picker
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Цвет")
                                    .foregroundColor(.white.opacity(0.9))
                                    .font(.system(size: 16, weight: .medium))
                                    .padding(.horizontal, 16)
                                
                                HStack(spacing: 12) {
                                    ForEach(colors, id: \.self) { color in
                                        Button(action: { selectedColor = color }) {
                                            Circle()
                                                .fill(colorFromString(color))
                                                .frame(width: 44, height: 44)
                                                .overlay(
                                                    Circle()
                                                        .strokeBorder(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                                )
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        GlassButton("Создать словарь", systemImage: "plus.circle.fill", color: .cyan) {
                            viewModel.createDictionary(name: name, description: description, color: selectedColor)
                            dismiss()
                        }
                        .disabled(name.isEmpty)
                        .opacity(name.isEmpty ? 0.5 : 1)
                    }
                    .padding()
                }
            }
            .navigationTitle("Новый словарь")
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
