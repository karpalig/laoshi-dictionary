/**
 * Форматирует определения словаря, выделяя:
 * - Римские цифры (I, II, III, IV, V, VI, VII)
 * - Пиньинь с тонами (Latin Extended: U+00C0-U+024F)
 * - Кириллические маркеры подразделов (А, Б)
 */

// Regex паттерны (используем Unicode диапазон для всех латинских диакритик)
const PATTERNS = {
    // Римские цифры в начале (I, II, III, IV, V, VI, VII)
    romanNumeral: /^(I{1,3}|IV|V|VI{0,3}|VII)(\s|,|$)/,
    
    // Римские цифры + пиньинь (I, băi или I ba)
    romanWithPinyin: /^(I{1,3}|IV|V|VI{0,3}|VII)[,\s]+([a-zA-Z\u00C0-\u024F·\-]+)/,
    
    // Кириллические маркеры подразделов (А, Б, и т.д.)
    cyrillicMarker: /^[АБВГДЕЖЗИи]\s/,
    
    // Пиньинь с тонами (для выделения отдельных слов-произношений)
    pinyinWithTones: /^[a-zA-Z\-]*[\u00C0-\u024F][a-zA-Z\u00C0-\u024F·,\-]*$/
};

/**
 * Проверяет, содержит ли строка тоновые знаки пиньиня
 */
function hasToneMarks(str) {
    return /[\u00C0-\u024F]/.test(str);
}

/**
 * Форматирует элемент определения (одну строку из массива d)
 * Возвращает HTML с <b> тегами для выделения
 */
function formatDefinitionItem(text) {
    if (!text) return '';
    
    // Проверяем паттерны в начале строки
    
    // 1. Римские цифры с пиньинем: "I, băi" или "II àihǎo"
    const romanPinyinMatch = text.match(PATTERNS.romanWithPinyin);
    if (romanPinyinMatch) {
        const [fullMatch, roman, pinyin] = romanPinyinMatch;
        const rest = text.slice(fullMatch.length);
        return `<b>${roman}, ${pinyin}</b>${rest}`;
    }
    
    // 2. Только римские цифры: "I гл." или "II сущ."
    const romanMatch = text.match(PATTERNS.romanNumeral);
    if (romanMatch) {
        const [fullMatch, roman] = romanMatch;
        const rest = text.slice(fullMatch.length);
        return `<b>${roman}</b> ${rest}`;
    }
    
    // 3. Кириллические маркеры: "А " или "Б "
    const cyrillicMatch = text.match(PATTERNS.cyrillicMarker);
    if (cyrillicMatch) {
        const marker = cyrillicMatch[0].trim();
        const rest = text.slice(cyrillicMatch[0].length);
        return `<b>${marker}</b> ${rest}`;
    }
    
    // 4. Чистый пиньинь с тонами в начале (как "àihào" или "-chūlai")
    const words = text.split(/\s+/);
    if (words.length > 0 && PATTERNS.pinyinWithTones.test(words[0])) {
        const rest = words.slice(1).join(' ');
        return `<b>${words[0]}</b>${rest ? ' ' + rest : ''}`;
    }
    
    return text;
}

/**
 * Форматирует весь массив определений
 */
function formatDefinitions(definitions) {
    if (!Array.isArray(definitions)) return [];
    return definitions.map(formatDefinitionItem);
}

export { formatDefinitionItem, formatDefinitions, hasToneMarks };

