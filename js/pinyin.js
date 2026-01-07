/**
 * Pinyin Module - Numbered to Tonal Conversion
 * Converts pinyin like "ni3 hao3" → "nǐ hǎo"
 */

const LaoshiPinyin = (() => {
  // Tone marks for each vowel [neutral, 1st, 2nd, 3rd, 4th]
  const TONES = {
    a: ['a', 'ā', 'á', 'ǎ', 'à'],
    e: ['e', 'ē', 'é', 'ě', 'è'],
    i: ['i', 'ī', 'í', 'ǐ', 'ì'],
    o: ['o', 'ō', 'ó', 'ǒ', 'ò'],
    u: ['u', 'ū', 'ú', 'ǔ', 'ù'],
    ü: ['ü', 'ǖ', 'ǘ', 'ǚ', 'ǜ'],
    v: ['ü', 'ǖ', 'ǘ', 'ǚ', 'ǜ']  // v as alias for ü
  };

  /**
   * Find vowel index to receive tone mark
   * Rules: a/e always get tone; ou → o gets tone; else last vowel
   */
  const findToneIndex = (syllable) => {
    const s = syllable.toLowerCase();
    
    // a or e always takes the tone
    const aIdx = s.indexOf('a');
    if (aIdx !== -1) return aIdx;
    
    const eIdx = s.indexOf('e');
    if (eIdx !== -1) return eIdx;
    
    // ou → o takes the tone
    const ouIdx = s.indexOf('ou');
    if (ouIdx !== -1) return ouIdx;
    
    // Otherwise last vowel
    for (let i = s.length - 1; i >= 0; i--) {
      if ('iouüv'.includes(s[i])) return i;
    }
    
    return -1;
  };

  /**
   * Convert single syllable with tone number to tonal pinyin
   * e.g., "ni3" → "nǐ", "lü4" → "lǜ"
   */
  const convertSyllable = (syllable) => {
    const match = syllable.match(/^([a-züv]+)([1-5])?$/i);
    if (!match) return syllable;
    
    let [, base, toneNum] = match;
    const tone = parseInt(toneNum) || 0;
    
    if (tone === 0 || tone === 5) return base;
    
    const idx = findToneIndex(base);
    if (idx === -1) return base;
    
    const vowel = base[idx].toLowerCase();
    const toneMap = TONES[vowel];
    
    if (!toneMap) return base;
    
    const toned = toneMap[tone];
    return base.slice(0, idx) + toned + base.slice(idx + 1);
  };

  /**
   * Convert full pinyin string
   * e.g., "ni3 hao3" → "nǐ hǎo", "ni3hao3" → "nǐhǎo"
   */
  const convert = (input) => {
    if (!input) return '';
    return input.replace(/[a-züv]+[1-5]?/gi, convertSyllable);
  };

  return { convert, convertSyllable };
})();

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
  module.exports = LaoshiPinyin;
}

