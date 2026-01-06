/**
 * 老师词典 - Database Module
 * IndexedDB operations using idb library
 */

const DB_NAME = 'laoshi-dictionary';
const DB_VERSION = 1;

let db = null;

/**
 * Initialize the database
 */
async function initDB() {
  if (db) return db;
  
  db = await idb.openDB(DB_NAME, DB_VERSION, {
    upgrade(database, oldVersion, newVersion, transaction) {
      // Words store - main dictionary
      if (!database.objectStoreNames.contains('words')) {
        const wordsStore = database.createObjectStore('words', { keyPath: 'id', autoIncrement: true });
        wordsStore.createIndex('word', 'w', { unique: false });
        wordsStore.createIndex('pinyin', 'p', { unique: false });
      }
      
      // Decks store - word lists
      if (!database.objectStoreNames.contains('decks')) {
        const decksStore = database.createObjectStore('decks', { keyPath: 'id' });
        decksStore.createIndex('type', 'type', { unique: false });
      }
      
      // Deck words store - words in each deck
      if (!database.objectStoreNames.contains('deckWords')) {
        const deckWordsStore = database.createObjectStore('deckWords', { keyPath: ['deckId', 'wordId'] });
        deckWordsStore.createIndex('deckId', 'deckId', { unique: false });
        deckWordsStore.createIndex('wordId', 'wordId', { unique: false });
      }
      
      // Settings store
      if (!database.objectStoreNames.contains('settings')) {
        database.createObjectStore('settings', { keyPath: 'key' });
      }
    }
  });
  
  return db;
}

/**
 * Check if dictionary is loaded
 */
async function isDictionaryLoaded() {
  const database = await initDB();
  const count = await database.count('words');
  return count > 0;
}

/**
 * Load dictionary from NDJSON file
 */
async function loadDictionary(progressCallback) {
  const database = await initDB();
  
  const response = await fetch('dictionary/dabkrs-light.ndjson');
  const text = await response.text();
  const lines = text.trim().split('\n');
  const total = lines.length;
  
  // Process in batches for better performance
  const BATCH_SIZE = 500;
  let processed = 0;
  
  for (let i = 0; i < lines.length; i += BATCH_SIZE) {
    const batch = lines.slice(i, i + BATCH_SIZE);
    const tx = database.transaction('words', 'readwrite');
    
    for (const line of batch) {
      if (line.trim()) {
        try {
          const word = JSON.parse(line);
          await tx.store.put(word);
        } catch (e) {
          console.warn('Failed to parse line:', line);
        }
      }
    }
    
    await tx.done;
    processed += batch.length;
    
    if (progressCallback) {
      progressCallback(processed, total);
    }
  }
  
  // Create default system decks
  await createSystemDecks();
  
  return processed;
}

/**
 * Create system decks (HSK levels + favorites)
 */
async function createSystemDecks() {
  const database = await initDB();
  
  const systemDecks = [
    { id: 'favorites', name: '⭐ Избранное', type: 'system', icon: 'star_fill', count: 0 },
    { id: 'hsk1', name: 'HSK 1', type: 'system', icon: 'book_fill', count: 0, file: 'dictionary/hsk-ru/hsk-level-1-ru.json' }
  ];
  
  const tx = database.transaction('decks', 'readwrite');
  for (const deck of systemDecks) {
    const existing = await tx.store.get(deck.id);
    if (!existing) {
      await tx.store.put(deck);
    }
  }
  await tx.done;
}

/**
 * Search words in dictionary
 */
async function searchWords(query, limit = 50) {
  if (!query || query.length < 1) return [];
  
  const database = await initDB();
  const results = [];
  const queryLower = query.toLowerCase();
  const seen = new Set();
  
  // Search by Chinese characters (exact prefix match)
  const cursorWord = await database.transaction('words').store.index('word').openCursor();
  let cursor = cursorWord;
  
  while (cursor && results.length < limit) {
    const word = cursor.value;
    if (word.w && word.w.startsWith(query) && !seen.has(word.w)) {
      results.push(word);
      seen.add(word.w);
    }
    cursor = await cursor.continue();
  }
  
  // If few results, also search by pinyin
  if (results.length < limit) {
    const allWords = await database.getAll('words');
    for (const word of allWords) {
      if (results.length >= limit) break;
      if (seen.has(word.w)) continue;
      
      // Search in pinyin
      if (word.p && word.p.toLowerCase().includes(queryLower)) {
        results.push(word);
        seen.add(word.w);
        continue;
      }
      
      // Search in definitions (Russian)
      if (word.d && Array.isArray(word.d)) {
        const defText = word.d.join(' ').toLowerCase();
        if (defText.includes(queryLower)) {
          results.push(word);
          seen.add(word.w);
        }
      }
    }
  }
  
  return results;
}

/**
 * Get all decks
 */
async function getAllDecks() {
  const database = await initDB();
  return await database.getAll('decks');
}

/**
 * Get deck by ID
 */
async function getDeck(deckId) {
  const database = await initDB();
  return await database.get('decks', deckId);
}

/**
 * Create user deck
 */
async function createDeck(name) {
  const database = await initDB();
  const id = 'user_' + Date.now();
  const deck = {
    id,
    name,
    type: 'user',
    icon: 'folder_fill',
    count: 0,
    createdAt: new Date().toISOString()
  };
  await database.put('decks', deck);
  return deck;
}

/**
 * Delete deck
 */
async function deleteDeck(deckId) {
  const database = await initDB();
  
  // Delete deck words first
  const tx = database.transaction(['deckWords', 'decks'], 'readwrite');
  const index = tx.objectStore('deckWords').index('deckId');
  let cursor = await index.openCursor(IDBKeyRange.only(deckId));
  
  while (cursor) {
    await cursor.delete();
    cursor = await cursor.continue();
  }
  
  // Delete deck
  await tx.objectStore('decks').delete(deckId);
  await tx.done;
}

/**
 * Load HSK deck words from JSON file
 */
async function loadHSKDeck(deckId) {
  const database = await initDB();
  const deck = await database.get('decks', deckId);
  
  if (!deck || !deck.file) {
    console.warn('Deck not found or has no file:', deckId);
    return [];
  }
  
  // Check if already loaded
  const existingWords = await getDeckWords(deckId);
  if (existingWords.length > 0) {
    return existingWords;
  }
  
  // Load from file
  try {
    const response = await fetch(deck.file);
    const data = await response.json();
    
    const words = data.words || data;
    const tx = database.transaction('deckWords', 'readwrite');
    
    for (const word of words) {
      await tx.store.put({
        deckId,
        wordId: word.id || word.word,
        word: word.word,
        pinyin: word.py || word.pinyin,
        translation: word.ru || (word.translations ? word.translations.join(', ') : ''),
        hsk: word.hsk
      });
    }
    
    await tx.done;
    
    // Update deck count
    await database.put('decks', { ...deck, count: words.length });
    
    return await getDeckWords(deckId);
  } catch (e) {
    console.error('Failed to load HSK deck:', e);
    return [];
  }
}

/**
 * Get words in a deck
 */
async function getDeckWords(deckId) {
  const database = await initDB();
  const words = await database.getAllFromIndex('deckWords', 'deckId', deckId);
  return words;
}

/**
 * Add word to deck
 */
async function addWordToDeck(deckId, word) {
  const database = await initDB();
  
  const deckWord = {
    deckId,
    wordId: word.w || word.id,
    word: word.w,
    pinyin: word.p,
    translation: Array.isArray(word.d) ? word.d[0] : word.d,
    hsk: word.h
  };
  
  await database.put('deckWords', deckWord);
  
  // Update deck count
  const deck = await database.get('decks', deckId);
  if (deck) {
    const count = await database.countFromIndex('deckWords', 'deckId', deckId);
    await database.put('decks', { ...deck, count });
  }
}

/**
 * Remove word from deck
 */
async function removeWordFromDeck(deckId, wordId) {
  const database = await initDB();
  await database.delete('deckWords', [deckId, wordId]);
  
  // Update deck count
  const deck = await database.get('decks', deckId);
  if (deck) {
    const count = await database.countFromIndex('deckWords', 'deckId', deckId);
    await database.put('decks', { ...deck, count });
  }
}

/**
 * Check if word is in favorites
 */
async function isWordInFavorites(wordId) {
  const database = await initDB();
  const entry = await database.get('deckWords', ['favorites', wordId]);
  return !!entry;
}

/**
 * Toggle word in favorites
 */
async function toggleFavorite(word) {
  const wordId = word.w || word.id;
  const isFav = await isWordInFavorites(wordId);
  
  if (isFav) {
    await removeWordFromDeck('favorites', wordId);
  } else {
    await addWordToDeck('favorites', word);
  }
  
  return !isFav;
}

/**
 * Get setting value
 */
async function getSetting(key, defaultValue = null) {
  const database = await initDB();
  const setting = await database.get('settings', key);
  return setting ? setting.value : defaultValue;
}

/**
 * Set setting value
 */
async function setSetting(key, value) {
  const database = await initDB();
  await database.put('settings', { key, value });
}

/**
 * Get database statistics
 */
async function getStats() {
  const database = await initDB();
  
  const wordsCount = await database.count('words');
  const decksCount = await database.count('decks');
  
  // Estimate database size
  let dbSize = '—';
  if (navigator.storage && navigator.storage.estimate) {
    const estimate = await navigator.storage.estimate();
    if (estimate.usage) {
      const mb = estimate.usage / (1024 * 1024);
      dbSize = mb < 1 ? `${Math.round(estimate.usage / 1024)} KB` : `${mb.toFixed(1)} MB`;
    }
  }
  
  return {
    wordsCount,
    decksCount,
    dbSize
  };
}

// Export functions
window.LaoshiDB = {
  initDB,
  isDictionaryLoaded,
  loadDictionary,
  searchWords,
  getAllDecks,
  getDeck,
  createDeck,
  deleteDeck,
  loadHSKDeck,
  getDeckWords,
  addWordToDeck,
  removeWordFromDeck,
  isWordInFavorites,
  toggleFavorite,
  getSetting,
  setSetting,
  getStats
};

