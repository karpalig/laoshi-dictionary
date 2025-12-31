import Foundation

class PinyinHelper {
    
    // MARK: - Tone Marks
    
    static let toneMarks: [Character: [Character]] = [
        "a": ["ā", "á", "ǎ", "à", "a"],
        "e": ["ē", "é", "ě", "è", "e"],
        "i": ["ī", "í", "ǐ", "ì", "i"],
        "o": ["ō", "ó", "ǒ", "ò", "o"],
        "u": ["ū", "ú", "ǔ", "ù", "u"],
        "ü": ["ǖ", "ǘ", "ǚ", "ǜ", "ü"]
    ]
    
    // MARK: - Pinyin Validation
    
    static func isValidPinyin(_ pinyin: String) -> Bool {
        let cleanPinyin = pinyin.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Check if contains valid pinyin characters
        let pinyinPattern = "^[a-zāáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜü\\s]+$"
        let regex = try? NSRegularExpression(pattern: pinyinPattern, options: [])
        let range = NSRange(location: 0, length: cleanPinyin.utf16.count)
        
        return regex?.firstMatch(in: cleanPinyin, options: [], range: range) != nil
    }
    
    // MARK: - Tone Number Conversion
    
    /// Converts numbered pinyin (ni3 hao3) to tone marks (nǐ hǎo)
    static func numberedToToneMarks(_ pinyin: String) -> String {
        var result = pinyin
        
        // Pattern to match pinyin syllables with tone numbers (1-4)
        let pattern = "([a-züA-ZÜ]+)([1-4])"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return result
        }
        
        let matches = regex.matches(in: result, options: [], range: NSRange(result.startIndex..., in: result))
        
        // Process matches in reverse to maintain string indices
        for match in matches.reversed() {
            if match.numberOfRanges == 3,
               let syllableRange = Range(match.range(at: 1), in: result),
               let toneRange = Range(match.range(at: 2), in: result) {
                
                let syllable = String(result[syllableRange])
                let toneNumber = Int(String(result[toneRange])) ?? 5
                
                let markedSyllable = addToneMark(to: syllable, tone: toneNumber)
                let fullRange = match.range
                
                if let fullMatchRange = Range(fullRange, in: result) {
                    result.replaceSubrange(fullMatchRange, with: markedSyllable)
                }
            }
        }
        
        return result
    }
    
    /// Adds tone mark to a pinyin syllable
    private static func addToneMark(to syllable: String, tone: Int) -> String {
        guard tone >= 1 && tone <= 4 else { return syllable }
        
        var result = syllable.lowercased()
        let toneIndex = tone - 1
        
        // Rules for tone mark placement:
        // 1. If there's an 'a' or 'e', it takes the tone mark
        // 2. If there's an 'ou', 'o' takes the tone mark
        // 3. Otherwise, the last vowel takes the tone mark
        
        if let aIndex = result.firstIndex(of: "a") {
            if let newChar = toneMarks["a"]?[toneIndex] {
                result.replaceSubrange(aIndex...aIndex, with: String(newChar))
            }
        } else if let eIndex = result.firstIndex(of: "e") {
            if let newChar = toneMarks["e"]?[toneIndex] {
                result.replaceSubrange(eIndex...eIndex, with: String(newChar))
            }
        } else if result.contains("ou"), let oIndex = result.firstIndex(of: "o") {
            if let newChar = toneMarks["o"]?[toneIndex] {
                result.replaceSubrange(oIndex...oIndex, with: String(newChar))
            }
        } else {
            // Find last vowel
            let vowels: [Character] = ["i", "o", "u", "ü"]
            for vowel in vowels.reversed() {
                if let index = result.lastIndex(of: vowel) {
                    if let newChar = toneMarks[vowel]?[toneIndex] {
                        result.replaceSubrange(index...index, with: String(newChar))
                        break
                    }
                }
            }
        }
        
        return result
    }
    
    // MARK: - Pinyin Formatting
    
    /// Formats pinyin with proper capitalization
    static func formatPinyin(_ pinyin: String) -> String {
        let words = pinyin.components(separatedBy: " ")
        return words.map { word in
            guard !word.isEmpty else { return word }
            return word.prefix(1).lowercased() + word.dropFirst().lowercased()
        }.joined(separator: " ")
    }
    
    /// Capitalizes first letter of pinyin
    static func capitalizePinyin(_ pinyin: String) -> String {
        guard !pinyin.isEmpty else { return pinyin }
        let formatted = formatPinyin(pinyin)
        return formatted.prefix(1).uppercased() + formatted.dropFirst()
    }
    
    // MARK: - HSK Level Detection
    
    /// Returns color for HSK level
    static func colorForHSKLevel(_ level: Int16) -> String {
        switch level {
        case 1: return "green"
        case 2: return "cyan"
        case 3: return "blue"
        case 4: return "purple"
        case 5: return "orange"
        case 6: return "pink"
        default: return "gray"
        }
    }
    
    // MARK: - Character Analysis
    
    /// Checks if string contains Chinese characters
    static func containsChinese(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            if (0x4E00...0x9FFF).contains(scalar.value) {
                return true
            }
        }
        return false
    }
    
    /// Counts Chinese characters in string
    static func chineseCharacterCount(_ text: String) -> Int {
        var count = 0
        for scalar in text.unicodeScalars {
            if (0x4E00...0x9FFF).contains(scalar.value) {
                count += 1
            }
        }
        return count
    }
    
    // MARK: - Search Helper
    
    /// Normalizes text for search (removes tones, converts to lowercase)
    static func normalizeForSearch(_ text: String) -> String {
        var normalized = text.lowercased()
        
        // Remove tone marks
        for (base, variants) in toneMarks {
            for variant in variants {
                normalized = normalized.replacingOccurrences(of: String(variant), with: String(base))
            }
        }
        
        return normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
