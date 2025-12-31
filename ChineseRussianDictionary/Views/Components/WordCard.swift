import SwiftUI

struct WordCard: View {
    let word: WordEntity
    let onTap: () -> Void
    let onFavorite: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(word.chinese)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(word.pinyin)
                                .font(.system(size: 14))
                                .foregroundColor(.cyan.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        Button(action: onFavorite) {
                            Image(systemName: word.isFavorite ? "star.fill" : "star")
                                .font(.system(size: 20))
                                .foregroundColor(word.isFavorite ? .yellow : .gray)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text(word.russian)
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.9))
                    
                    HStack {
                        if word.hskLevel > 0 {
                            Text("HSK \(word.hskLevel)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.purple.opacity(0.6))
                                )
                        }
                        
                        if !word.examplesArray.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "text.quote")
                                Text("\(word.examplesArray.count)")
                            }
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        if let dict = word.dictionary {
                            Text(dict.name)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .padding(16)
            }
        }
        .buttonStyle(.plain)
    }
}
