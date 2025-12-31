// IndexedDB Database Manager
const DB_NAME = 'ChineseRussianDictionary';
const DB_VERSION = 1;

class DatabaseManager {
    constructor() {
        this.db = null;
    }

    async init() {
        return new Promise((resolve, reject) => {
            const request = indexedDB.open(DB_NAME, DB_VERSION);

            request.onerror = () => reject(request.error);
            request.onsuccess = () => {
                this.db = request.result;
                resolve(this.db);
            };

            request.onupgradeneeded = (event) => {
                const db = event.target.result;

                // Dictionaries store
                if (!db.objectStoreNames.contains('dictionaries')) {
                    const dictStore = db.createObjectStore('dictionaries', { keyPath: 'id' });
                    dictStore.createIndex('createdAt', 'createdAt', { unique: false });
                }

                // Words store
                if (!db.objectStoreNames.contains('words')) {
                    const wordStore = db.createObjectStore('words', { keyPath: 'id' });
                    wordStore.createIndex('dictionaryId', 'dictionaryId', { unique: false });
                    wordStore.createIndex('isFavorite', 'isFavorite', { unique: false });
                    wordStore.createIndex('createdAt', 'createdAt', { unique: false });
                }

                // Examples store
                if (!db.objectStoreNames.contains('examples')) {
                    const exampleStore = db.createObjectStore('examples', { keyPath: 'id' });
                    exampleStore.createIndex('wordId', 'wordId', { unique: false });
                }
            };
        });
    }

    // Generic CRUD operations
    async add(storeName, data) {
        const tx = this.db.transaction(storeName, 'readwrite');
        const store = tx.objectStore(storeName);
        return store.add(data);
    }

    async put(storeName, data) {
        const tx = this.db.transaction(storeName, 'readwrite');
        const store = tx.objectStore(storeName);
        return store.put(data);
    }

    async get(storeName, id) {
        const tx = this.db.transaction(storeName, 'readonly');
        const store = tx.objectStore(storeName);
        return store.get(id);
    }

    async getAll(storeName) {
        return new Promise((resolve, reject) => {
            const tx = this.db.transaction(storeName, 'readonly');
            const store = tx.objectStore(storeName);
            const request = store.getAll();
            
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
    }

    async getAllByIndex(storeName, indexName, value) {
        return new Promise((resolve, reject) => {
            const tx = this.db.transaction(storeName, 'readonly');
            const store = tx.objectStore(storeName);
            const index = store.index(indexName);
            const request = index.getAll(value);
            
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
    }

    async delete(storeName, id) {
        const tx = this.db.transaction(storeName, 'readwrite');
        const store = tx.objectStore(storeName);
        return store.delete(id);
    }

    // Dictionary operations
    async createDictionary(name, description, color) {
        const dictionary = {
            id: this.generateId(),
            name,
            description,
            color: color || 'cyan',
            isActive: true,
            createdAt: new Date().toISOString()
        };
        await this.add('dictionaries', dictionary);
        return dictionary;
    }

    async getAllDictionaries() {
        const dicts = await this.getAll('dictionaries');
        return dicts.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    }

    async updateDictionary(id, updates) {
        const dict = await this.get('dictionaries', id);
        const updated = { ...dict, ...updates };
        await this.put('dictionaries', updated);
        return updated;
    }

    async deleteDictionary(id) {
        // Delete all words in this dictionary
        const words = await this.getAllByIndex('words', 'dictionaryId', id);
        for (const word of words) {
            await this.deleteWord(word.id);
        }
        await this.delete('dictionaries', id);
    }

    // Word operations
    async createWord(chinese, pinyin, russian, dictionaryId, hskLevel = 0) {
        const word = {
            id: this.generateId(),
            chinese,
            pinyin: PinyinHelper.numberedToToneMarks(pinyin),
            russian,
            dictionaryId,
            hskLevel,
            isFavorite: false,
            createdAt: new Date().toISOString(),
            lastAccessed: null
        };
        await this.add('words', word);
        return word;
    }

    async getAllWords() {
        const words = await this.getAll('words');
        return words.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    }

    async getWordsByDictionary(dictionaryId) {
        return await this.getAllByIndex('words', 'dictionaryId', dictionaryId);
    }

    async getFavoriteWords() {
        return await this.getAllByIndex('words', 'isFavorite', true);
    }

    async updateWord(id, updates) {
        const word = await this.get('words', id);
        const updated = { ...word, ...updates };
        await this.put('words', updated);
        return updated;
    }

    async deleteWord(id) {
        // Delete all examples for this word
        const examples = await this.getAllByIndex('examples', 'wordId', id);
        for (const example of examples) {
            await this.delete('examples', example.id);
        }
        await this.delete('words', id);
    }

    async toggleFavorite(id) {
        const word = await this.get('words', id);
        return await this.updateWord(id, { isFavorite: !word.isFavorite });
    }

    async updateLastAccessed(id) {
        return await this.updateWord(id, { lastAccessed: new Date().toISOString() });
    }

    // Example operations
    async createExample(wordId, chineseSentence, pinyinSentence, russianTranslation) {
        const example = {
            id: this.generateId(),
            wordId,
            chineseSentence,
            pinyinSentence: PinyinHelper.numberedToToneMarks(pinyinSentence),
            russianTranslation,
            createdAt: new Date().toISOString()
        };
        await this.add('examples', example);
        return example;
    }

    async getExamplesByWord(wordId) {
        return await this.getAllByIndex('examples', 'wordId', wordId);
    }

    async updateExample(id, updates) {
        const example = await this.get('examples', id);
        const updated = { ...example, ...updates };
        await this.put('examples', updated);
        return updated;
    }

    async deleteExample(id) {
        await this.delete('examples', id);
    }

    // Sample data
    async createSampleData() {
        // Create default dictionary
        const dict = await this.createDictionary(
            'Основной словарь',
            'Основной китайско-русский словарь',
            'cyan'
        );

        // Add sample words
        const sampleWords = [
            { chinese: '你好', pinyin: 'nǐ hǎo', russian: 'Привет', hsk: 1 },
            { chinese: '谢谢', pinyin: 'xièxie', russian: 'Спасибо', hsk: 1 },
            { chinese: '再见', pinyin: 'zàijiàn', russian: 'До свидания', hsk: 1 },
            { chinese: '学习', pinyin: 'xuéxí', russian: 'Учиться', hsk: 2 },
            { chinese: '汉语', pinyin: 'hànyǔ', russian: 'Китайский язык', hsk: 3 }
        ];

        for (const wordData of sampleWords) {
            const word = await this.createWord(
                wordData.chinese,
                wordData.pinyin,
                wordData.russian,
                dict.id,
                wordData.hsk
            );

            // Add example for first word
            if (wordData.chinese === '你好') {
                await this.createExample(
                    word.id,
                    '你好，我是学生。',
                    'Nǐ hǎo, wǒ shì xuésheng.',
                    'Привет, я студент.'
                );
            }
        }

        return dict;
    }

    // Utility
    generateId() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
            const r = Math.random() * 16 | 0;
            const v = c === 'x' ? r : (r & 0x3 | 0x8);
            return v.toString(16);
        });
    }
}

// Initialize global database instance
const db = new DatabaseManager();
