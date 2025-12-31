import SwiftUI

// Extension to help with Chinese input
extension View {
    func chineseKeyboard() -> some View {
        self.keyboardType(.default)
    }
    
    func pinyinKeyboard() -> some View {
        self.keyboardType(.asciiCapable)
    }
}

// Custom text field for Chinese input with pinyin suggestions
struct ChineseTextField: View {
    let placeholder: String
    @Binding var text: String
    var systemImage: String?
    var autoConvertTones: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            if let image = systemImage {
                Image(systemName: image)
                    .foregroundColor(.cyan.opacity(0.7))
                    .font(.system(size: 18))
            }
            
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .font(.system(size: 16))
                .onChange(of: text) { oldValue, newValue in
                    if autoConvertTones {
                        // Auto-convert numbered pinyin to tone marks
                        let converted = PinyinHelper.numberedToToneMarks(newValue)
                        if converted != newValue {
                            text = converted
                        }
                    }
                }
        }
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

// Pinyin input helper with tone number conversion
struct PinyinInputHelper: View {
    @Binding var pinyin: String
    @State private var showHelper = false
    
    let toneButtons = [
        ("1", "ˉ", "First tone (high level)"),
        ("2", "ˊ", "Second tone (rising)"),
        ("3", "ˇ", "Third tone (falling-rising)"),
        ("4", "ˋ", "Fourth tone (falling)"),
        ("5", "·", "Neutral tone")
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: { showHelper.toggle() }) {
                    HStack(spacing: 6) {
                        Image(systemName: showHelper ? "chevron.up" : "chevron.down")
                        Text("Помощь с тонами")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.cyan)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            
            if showHelper {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Введите цифру тона после слога:")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(toneButtons, id: \.0) { number, mark, description in
                            HStack(spacing: 8) {
                                Text(number)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.cyan)
                                    .frame(width: 20)
                                
                                Text(mark)
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .frame(width: 20)
                                
                                Text(description)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                    
                    Text("Пример: ni3 hao3 → nǐ hǎo")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.cyan.opacity(0.8))
                        .padding(.top, 4)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                )
                .padding(.horizontal, 16)
            }
        }
    }
}
