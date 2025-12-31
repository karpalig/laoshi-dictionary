// Pinyin Helper Utilities
const PinyinHelper = {
    // Tone marks mapping
    toneMarks: {
        'a': ['ā', 'á', 'ǎ', 'à', 'a'],
        'e': ['ē', 'é', 'ě', 'è', 'e'],
        'i': ['ī', 'í', 'ǐ', 'ì', 'i'],
        'o': ['ō', 'ó', 'ǒ', 'ò', 'o'],
        'u': ['ū', 'ú', 'ǔ', 'ù', 'u'],
        'ü': ['ǖ', 'ǘ', 'ǚ', 'ǜ', 'ü']
    },

    // Converts numbered pinyin (ni3 hao3) to tone marks (nǐ hǎo)
    numberedToToneMarks(pinyin) {
        let result = pinyin;
        const regex = /([a-züA-ZÜ]+)([1-4])/g;
        const matches = [];
        let match;
        
        while ((match = regex.exec(result)) !== null) {
            matches.push({
                full: match[0],
                syllable: match[1],
                tone: parseInt(match[2]),
                index: match.index
            });
        }
        
        // Process matches in reverse to maintain string indices
        for (let i = matches.length - 1; i >= 0; i--) {
            const m = matches[i];
            const markedSyllable = this.addToneMark(m.syllable, m.tone);
            result = result.slice(0, m.index) + markedSyllable + result.slice(m.index + m.full.length);
        }
        
        return result;
    },

    // Adds tone mark to a pinyin syllable
    addToneMark(syllable, tone) {
        if (tone < 1 || tone > 4) return syllable;
        
        let result = syllable.toLowerCase();
        const toneIndex = tone - 1;
        
        // Rules for tone mark placement:
        // 1. If there's an 'a' or 'e', it takes the tone mark
        // 2. If there's an 'ou', 'o' takes the tone mark
        // 3. Otherwise, the last vowel takes the tone mark
        
        if (result.includes('a')) {
            const index = result.indexOf('a');
            result = result.slice(0, index) + this.toneMarks['a'][toneIndex] + result.slice(index + 1);
        } else if (result.includes('e')) {
            const index = result.indexOf('e');
            result = result.slice(0, index) + this.toneMarks['e'][toneIndex] + result.slice(index + 1);
        } else if (result.includes('ou')) {
            const index = result.indexOf('o');
            result = result.slice(0, index) + this.toneMarks['o'][toneIndex] + result.slice(index + 1);
        } else {
            // Find last vowel
            const vowels = ['i', 'o', 'u', 'ü'];
            for (const vowel of vowels.reverse()) {
                const index = result.lastIndexOf(vowel);
                if (index !== -1) {
                    result = result.slice(0, index) + this.toneMarks[vowel][toneIndex] + result.slice(index + 1);
                    break;
                }
            }
        }
        
        return result;
    },

    // Normalizes text for search (removes tones, converts to lowercase)
    normalizeForSearch(text) {
        let normalized = text.toLowerCase();
        
        // Remove tone marks
        for (const [base, variants] of Object.entries(this.toneMarks)) {
            for (const variant of variants) {
                normalized = normalized.replace(new RegExp(variant, 'g'), base);
            }
        }
        
        return normalized.trim();
    },

    // Checks if string contains Chinese characters
    containsChinese(text) {
        return /[\u4e00-\u9fff]/.test(text);
    },

    // Counts Chinese characters in string
    chineseCharacterCount(text) {
        const matches = text.match(/[\u4e00-\u9fff]/g);
        return matches ? matches.length : 0;
    },

    // Returns color for HSK level
    colorForHSKLevel(level) {
        const colors = {
            1: '#22c55e', // green
            2: '#00CCFF', // cyan
            3: '#3b82f6', // blue
            4: '#8b5cf6', // purple
            5: '#f97316', // orange
            6: '#ec4899'  // pink
        };
        return colors[level] || '#6b7280'; // gray
    }
};
