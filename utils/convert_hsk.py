#!/usr/bin/env python3
"""
Конвертер HSK словарей из github.com/clem109/hsk-vocabulary
в наш формат JSON с русскими переводами
"""

import json
import requests
import re
from typing import List, Dict

# Словарь для конвертации pinyin с тонами в числовой формат
TONE_MARKS = {
    'ā': 'a1', 'á': 'a2', 'ǎ': 'a3', 'à': 'a4', 'a': 'a',
    'ē': 'e1', 'é': 'e2', 'ě': 'e3', 'è': 'e4', 'e': 'e',
    'ī': 'i1', 'í': 'i2', 'ǐ': 'i3', 'ì': 'i4', 'i': 'i',
    'ō': 'o1', 'ó': 'o2', 'ǒ': 'o3', 'ò': 'o4', 'o': 'o',
    'ū': 'u1', 'ú': 'u2', 'ǔ': 'u3', 'ù': 'u4', 'u': 'u',
    'ǖ': 'v1', 'ǘ': 'v2', 'ǚ': 'v3', 'ǜ': 'v4', 'ü': 'v',
}

# Базовые переводы (английский -> русский)
COMMON_TRANSLATIONS = {
    'to love': 'любить',
    'to be fond of': 'нравиться',
    'to like': 'любить',
    'eight': 'восемь',
    'father': 'отец',
    'papa': 'папа',
    'cup': 'чашка',
    'glass': 'стакан',
    'Beijing': 'Пекин',
    'book': 'книга',
    'not': 'не',
    "you're welcome": 'пожалуйста',
    'impolite': 'невежливый',
    'tea': 'чай',
    'to eat': 'есть',
    'taxi': 'такси',
    'to phone': 'звонить',
    'telephone': 'телефон',
    'big': 'большой',
    'particle': 'частица',
    "o'clock": 'час',
    'point': 'точка',
    'computer': 'компьютер',
    'television': 'телевизор',
    'TV': 'ТВ',
    'movie': 'фильм',
    'film': 'кино',
    'thing': 'вещь',
    'stuff': 'предмет',
    'all': 'все',
    'both': 'оба',
    'to read': 'читать',
    'sorry': 'извините',
    'excuse me': 'простите',
    'many': 'много',
    'much': 'много',
    'how many': 'сколько',
    'how much': 'сколько',
    'son': 'сын',
    'two': 'два',
    'restaurant': 'ресторан',
    'airplane': 'самолет',
    'plane': 'самолет',
    'minute': 'минута',
    'happy': 'радостный',
    'glad': 'веселый',
    'classifier': 'счетное слово',
    'measure word': 'счетное слово',
    'to work': 'работать',
    'work': 'работа',
    'dog': 'собака',
    'Chinese language': 'китайский язык',
    'good': 'хороший',
    'well': 'хорошо',
    'number': 'номер',
    'date': 'дата',
    'to drink': 'пить',
    'and': 'и',
    'with': 'с',
    'very': 'очень',
    'behind': 'сзади',
    'back': 'позади',
    'to return': 'возвращаться',
    'can': 'уметь',
    'to be able to': 'мочь',
    'how many': 'сколько',
    'home': 'дом',
    'family': 'семья',
    'to call': 'звать',
    'to be called': 'называться',
    'today': 'сегодня',
    'nine': 'девять',
    'to open': 'открывать',
    'to see': 'смотреть',
    'to look': 'смотреть',
    'to watch': 'смотреть',
    'yuan': 'юань',
    'to come': 'приходить',
    'teacher': 'учитель',
    'cold': 'холодный',
    'inside': 'внутри',
    'in': 'в',
    'six': 'шесть',
    'mother': 'мама',
    'mom': 'мама',
    'question particle': 'вопросительная частица',
    'to buy': 'покупать',
    'cat': 'кошка',
    "it doesn't matter": 'ничего',
    'never mind': 'не важно',
    'to not have': 'не иметь',
    "don't have": 'нет',
    'rice': 'рис',
    'cooked rice': 'вареный рис',
    'name': 'имя',
    'tomorrow': 'завтра',
    'which': 'который',
    'what': 'какой',
    'where': 'где',
    'that': 'тот',
    'to be able': 'мочь',
    'you': 'ты',
    'year': 'год',
    'daughter': 'дочь',
    'friend': 'друг',
    'pretty': 'красивый',
    'beautiful': 'красивый',
    'apple': 'яблоко',
    'seven': 'семь',
    'front': 'впереди',
    'before': 'перед',
    'money': 'деньги',
    'please': 'пожалуйста',
    'to go': 'идти',
    'hot': 'горячий',
    'person': 'человек',
    'people': 'люди',
    'to know': 'знать',
    'to recognize': 'узнавать',
    'three': 'три',
    'store': 'магазин',
    'shop': 'магазин',
    'up': 'верх',
    'on': 'наверху',
    'morning': 'утро',
    'few': 'мало',
    'little': 'немного',
    'who': 'кто',
    'what': 'что',
    'ten': 'десять',
    'time': 'время',
    'to be': 'быть',
    'yes': 'да',
    'water': 'вода',
    'fruit': 'фрукты',
    'to sleep': 'спать',
    'to say': 'говорить',
    'to speak': 'говорить',
    'four': 'четыре',
    'years old': 'лет',
    'age': 'возраст',
    'he': 'он',
    'she': 'она',
    'too': 'слишком',
    'weather': 'погода',
    'to listen': 'слушать',
    'to hear': 'слышать',
    'classmate': 'одноклассник',
    'hello': 'алло',
    'hey': 'эй',
    'I': 'я',
    'me': 'я',
    'we': 'мы',
    'us': 'мы',
    'five': 'пять',
    'to be fond of': 'нравиться',
    'down': 'низ',
    'under': 'внизу',
    'afternoon': 'день',
    'to rain': 'идет дождь',
    'Mr.': 'господин',
    'mister': 'мистер',
    'now': 'сейчас',
    'to think': 'думать',
    'to want': 'хотеть',
    'small': 'маленький',
    'miss': 'мисс',
    'some': 'несколько',
    'a little': 'немного',
    'to write': 'писать',
    'thank you': 'спасибо',
    'thanks': 'спасибо',
    'week': 'неделя',
    'student': 'студент',
    'pupil': 'ученик',
    'to study': 'учиться',
    'to learn': 'изучать',
    'school': 'школа',
    'one': 'один',
    'a bit': 'немного',
    'clothing': 'одежда',
    'clothes': 'одежда',
    'doctor': 'врач',
    'hospital': 'больница',
    'chair': 'стул',
    'to have': 'иметь',
    'month': 'месяц',
    'at': 'в',
    'to be at': 'находиться',
    'goodbye': 'до свидания',
    'how': 'как',
    'how about': 'как насчет',
    'this': 'этот',
    'China': 'Китай',
    'noon': 'полдень',
    'midday': 'полдень',
    'to live': 'жить',
    'to reside': 'проживать',
    'table': 'стол',
    'desk': 'стол',
    'character': 'иероглиф',
    'word': 'слово',
    'yesterday': 'вчера',
    'to sit': 'сидеть',
    'to do': 'делать',
    'to make': 'делать',
}

def convert_pinyin_to_numbered(pinyin: str) -> str:
    """Конвертирует pinyin с тонами в числовой формат"""
    # Убираем пробелы между слогами для составных слов
    # но сохраняем пробелы между словами
    result = pinyin
    
    # Заменяем все тонированные гласные
    for tone_char, numbered in TONE_MARKS.items():
        result = result.replace(tone_char, numbered)
    
    # Убираем лишние пробелы внутри слова
    result = result.replace(' ', '')
    
    return result

def translate_to_russian(english_translations: List[str]) -> str:
    """Простой перевод английских значений на русский"""
    translations = []
    seen = set()
    
    for eng in english_translations[:4]:  # Берем первые 4 перевода
        eng_clean = eng.lower().strip()
        
        # Убираем технические пометки CL:, [wèi] и т.д.
        eng_clean = re.sub(r'CL:.*', '', eng_clean).strip()
        eng_clean = re.sub(r'\[.*?\]', '', eng_clean).strip()
        eng_clean = re.sub(r'\(.*?\)', '', eng_clean).strip()
        eng_clean = re.sub(r'[|]', ' ', eng_clean).strip()
        
        if not eng_clean or eng_clean in seen:
            continue
            
        seen.add(eng_clean)
        
        # Точное совпадение
        if eng_clean in COMMON_TRANSLATIONS:
            translations.append(COMMON_TRANSLATIONS[eng_clean])
        else:
            # Ищем частичное совпадение по началу фразы
            found = False
            for eng_key, rus_val in COMMON_TRANSLATIONS.items():
                if eng_clean.startswith(eng_key) or eng_key.startswith(eng_clean):
                    if rus_val not in translations:
                        translations.append(rus_val)
                    found = True
                    break
            
            # Если перевода нет, берем английский (будет понятно что нужно перевести)
            if not found and len(translations) < 2:
                translations.append(eng_clean)
    
    # Если ничего не нашли, берем первый английский вариант
    if not translations and english_translations:
        return english_translations[0].split('CL:')[0].strip()
    
    return ', '.join(translations[:2])  # Максимум 2 перевода

def download_hsk_level(level: int) -> List[Dict]:
    """Скачивает HSK словарь указанного уровня"""
    url = f"https://raw.githubusercontent.com/clem109/hsk-vocabulary/master/hsk-vocab-json/hsk-level-{level}.json"
    print(f"📥 Загружаю HSK {level}...")
    
    response = requests.get(url)
    response.raise_for_status()
    
    data = response.json()
    print(f"✅ Загружено {len(data)} слов")
    
    return data

def convert_to_our_format(hsk_data: List[Dict], level: int) -> Dict:
    """Конвертирует в наш формат"""
    words = []
    
    for item in hsk_data:
        pinyin_numbered = convert_pinyin_to_numbered(item['pinyin'])
        russian = translate_to_russian(item['translations'])
        
        words.append({
            'chinese': item['hanzi'],
            'pinyin': pinyin_numbered,
            'russian': russian,
            'hskLevel': level
        })
    
    return {
        'name': f'HSK {level}',
        'description': f'HSK уровень {level} ({len(words)} слов)',
        'color': ['green', 'blue', 'cyan', 'purple', 'pink', 'orange'][level - 1],
        'words': words,
        'version': '1.0',
        'source': 'github.com/clem109/hsk-vocabulary'
    }

def main():
    """Конвертирует все 6 уровней HSK"""
    for level in range(1, 7):
        try:
            # Скачиваем
            hsk_data = download_hsk_level(level)
            
            # Конвертируем
            print(f"🔄 Конвертирую HSK {level}...")
            our_format = convert_to_our_format(hsk_data, level)
            
            # Сохраняем
            filename = f'../examples/hsk{level}_from_clem.json'
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(our_format, f, ensure_ascii=False, indent=2)
            
            print(f"✅ Сохранено: {filename}\n")
            
        except Exception as e:
            print(f"❌ Ошибка HSK {level}: {e}\n")

if __name__ == '__main__':
    main()
