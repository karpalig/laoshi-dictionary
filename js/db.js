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
  
  try {
    console.log('[LaoshiDB] Initializing database...');
    db = await idb.openDB(DB_NAME, DB_VERSION, {
      upgrade(database, oldVersion, newVersion, transaction) {
        console.log(`[LaoshiDB] Upgrading database from version ${oldVersion} to ${newVersion}`);
        
        // Words store - main dictionary
        if (!database.objectStoreNames.contains('words')) {
          console.log('[LaoshiDB] Creating words store...');
          const wordsStore = database.createObjectStore('words', { keyPath: 'id', autoIncrement: true });
          wordsStore.createIndex('word', 'w', { unique: false });
          wordsStore.createIndex('pinyin', 'p', { unique: false });
        }
        
        // Decks store - word lists
        if (!database.objectStoreNames.contains('decks')) {
          console.log('[LaoshiDB] Creating decks store...');
          const decksStore = database.createObjectStore('decks', { keyPath: 'id' });
          decksStore.createIndex('type', 'type', { unique: false });
        }
        
        // Deck words store - words in each deck
        if (!database.objectStoreNames.contains('deckWords')) {
          console.log('[LaoshiDB] Creating deckWords store...');
          const deckWordsStore = database.createObjectStore('deckWords', { keyPath: ['deckId', 'wordId'] });
          deckWordsStore.createIndex('deckId', 'deckId', { unique: false });
          deckWordsStore.createIndex('wordId', 'wordId', { unique: false });
        }
        
        // Settings store
        if (!database.objectStoreNames.contains('settings')) {
          console.log('[LaoshiDB] Creating settings store...');
          database.createObjectStore('settings', { keyPath: 'key' });
        }
      }
    });
    
    console.log('[LaoshiDB] Database initialized successfully');
    return db;
  } catch (error) {
    console.error('[LaoshiDB] Failed to initialize database:', error);
    throw new Error(`Database initialization failed: ${error.message}`);
  }
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
 * Get available dictionaries from index.json
 */
async function getAvailableDictionaries() {
  try {
    const response = await fetch('dictionary/index.json');
    const data = await response.json();
    return data;
  } catch (e) {
    console.error('Failed to load dictionary index:', e);
    return { dictionaries: [], default: null };
  }
}

/**
 * Get current dictionary ID from settings
 */
async function getCurrentDictionary() {
  return await getSetting('currentDictionary', null);
}

/**
 * Set current dictionary ID in settings
 */
async function setCurrentDictionary(dictionaryId) {
  await setSetting('currentDictionary', dictionaryId);
}

/**
 * Load dictionary from NDJSON file
 * @param {string} filePath - Path to the dictionary file (optional, uses setting or default)
 * @param {function} progressCallback - Progress callback (processed, total)
 */
async function loadDictionary(filePath, progressCallback) {
  try {
    console.log('[LaoshiDB] Loading dictionary...');
    const database = await initDB();
    
    // If no file path provided, get from settings or use default
    if (!filePath) {
      const index = await getAvailableDictionaries();
      const currentId = await getCurrentDictionary();
      
      if (currentId) {
        const dict = index.dictionaries.find(d => d.id === currentId);
        filePath = dict ? dict.file : null;
      }
      
      if (!filePath && index.default) {
        const defaultDict = index.dictionaries.find(d => d.id === index.default);
        filePath = defaultDict ? defaultDict.file : 'dictionary/dabkrs-light.ndjson';
      }
      
      filePath = filePath || 'dictionary/dabkrs-light.ndjson';
    }
    
    console.log(`[LaoshiDB] Loading from: ${filePath}`);
    
    // Clear existing words before loading new dictionary
    try {
      const clearTx = database.transaction('words', 'readwrite');
      await clearTx.store.clear();
      await clearTx.done;
      console.log('[LaoshiDB] Cleared existing words');
    } catch (error) {
      console.error('[LaoshiDB] Failed to clear existing words:', error);
      throw new Error('Failed to clear existing dictionary data');
    }
    
    // Fetch dictionary file
    let response;
    try {
      response = await fetch(filePath);
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
    } catch (error) {
      console.error('[LaoshiDB] Failed to fetch dictionary:', error);
      throw new Error(`Failed to download dictionary file: ${error.message}`);
    }
    
    // Parse NDJSON
    let text, lines;
    try {
      text = await response.text();
      lines = text.trim().split('\n');
      console.log(`[LaoshiDB] Parsing ${lines.length} entries...`);
    } catch (error) {
      console.error('[LaoshiDB] Failed to parse dictionary text:', error);
      throw new Error('Failed to parse dictionary file');
    }
    
    const total = lines.length;
    
    // Process in batches for better performance
    const BATCH_SIZE = 500;
    let processed = 0;
    let parseErrors = 0;
    
    try {
      for (let i = 0; i < lines.length; i += BATCH_SIZE) {
        const batch = lines.slice(i, i + BATCH_SIZE);
        const tx = database.transaction('words', 'readwrite');
        
        for (const line of batch) {
          if (line.trim()) {
            try {
              const word = JSON.parse(line);
              await tx.store.put(word);
            } catch (e) {
              parseErrors++;
              if (parseErrors <= 10) {
                console.warn('[LaoshiDB] Failed to parse line:', line.substring(0, 100), e.message);
              }
            }
          }
        }
        
        await tx.done;
        processed += batch.length;
        
        if (progressCallback) {
          progressCallback(processed, total);
        }
      }
      
      if (parseErrors > 0) {
        console.warn(`[LaoshiDB] Completed with ${parseErrors} parse errors`);
      }
    } catch (error) {
      console.error('[LaoshiDB] Failed during batch processing:', error);
      throw new Error(`Failed to save dictionary data: ${error.message}`);
    }
    
    // Create default system decks
    try {
      await createSystemDecks();
    } catch (error) {
      console.error('[LaoshiDB] Failed to create system decks:', error);
      // Non-critical, continue
    }
    
    console.log(`[LaoshiDB] Successfully loaded ${processed} entries`);
    return processed;
  } catch (error) {
    console.error('[LaoshiDB] loadDictionary failed:', error);
    throw error;
  }
}

/**
 * Create system decks (HSK levels + favorites)
 */
async function createSystemDecks() {
  const database = await initDB();
  
  const systemDecks = [
    { id: 'favorites', name: 'Избранное', type: 'system', icon: 'star', count: 0 },
    { id: 'hsk1', name: 'HSK 1', type: 'system', icon: 'book', count: 0, file: 'dictionary/hsk-ru/hsk-level-1-ru.json' }
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
  
  try {
    console.log(`[LaoshiDB] Searching for: "${query}"`);
    const database = await initDB();
    const queryLower = query.toLowerCase();
    const seen = new Set();
  
  // Collect results with match type for sorting
  const chineseMatches = [];    // Priority 1: Chinese character match
  const pinyinExact = [];       // Priority 2: Pinyin exact match (single char words)
  const pinyinStartsWith = [];  // Priority 3: Pinyin starts with query
  const pinyinIncludes = [];    // Priority 4: Pinyin contains query
  const definitionMatches = []; // Priority 5: Russian definition contains query
  
  // Search by Chinese characters (exact prefix match)
  const cursorWord = await database.transaction('words').store.index('word').openCursor();
  let cursor = cursorWord;
  
  while (cursor) {
    const word = cursor.value;
    if (word.w && word.w.startsWith(query) && !seen.has(word.w)) {
      chineseMatches.push(word);
      seen.add(word.w);
    }
    cursor = await cursor.continue();
  }
  
  // Search all words for pinyin and definition matches
  const allWords = await database.getAll('words');
  
  for (const word of allWords) {
    if (seen.has(word.w)) continue;
    
    const pinyinLower = (word.p || '').toLowerCase();
    
    // Search in pinyin
    if (pinyinLower.includes(queryLower)) {
      seen.add(word.w);
      
      // Check if pinyin starts with query (without tone numbers)
      const pinyinNoTones = pinyinLower.replace(/[0-9]/g, '');
      const startsWithMatch = pinyinLower.startsWith(queryLower) || pinyinNoTones.startsWith(queryLower);
      
      if (startsWithMatch) {
        // Single character words with exact pinyin match get highest priority
        if (word.w.length === 1 && (pinyinNoTones === queryLower || pinyinLower.replace(/[0-9]/g, '') === queryLower)) {
          pinyinExact.push(word);
        } else {
          pinyinStartsWith.push(word);
        }
      } else {
        pinyinIncludes.push(word);
      }
      continue;
    }
    
    // Search in definitions (Russian) - only if no pinyin match
    if (word.d && Array.isArray(word.d)) {
      const defText = word.d.join(' ').toLowerCase();
      if (defText.includes(queryLower)) {
        definitionMatches.push(word);
        seen.add(word.w);
      }
    }
  }
  
  // Sort each group by HSK level (lower = more common) and word length (shorter = more basic)
  const sortByRelevance = (a, b) => {
    const hskA = a.h || 99;
    const hskB = b.h || 99;
    if (hskA !== hskB) return hskA - hskB;
    return (a.w || '').length - (b.w || '').length;
  };
  
  // Sort definition matches by relevance: prioritize words where query appears at start of definition
  const sortDefinitionsByRelevance = (a, b) => {
    // Get first definition and strip BKRS formatting (number prefixes, tags)
    const cleanDef = (d) => {
      if (!Array.isArray(d) || !d[0]) return '';
      return d[0]
        .toLowerCase()
        .replace(/^\[b\][^\[]*\[\/b\]\s*/g, '')  // Remove [b]...[/b] tags
        .replace(/^[0-9]+\)\s*/g, '')            // Remove "1) " number prefixes
        .replace(/^[ivx]+[,.\s]+/gi, '')         // Remove Roman numerals
        .trim();
    };
    
    const defA = cleanDef(a.d);
    const defB = cleanDef(b.d);
    
    // Priority 1: Definition starts with query
    const aStartsWith = defA.startsWith(queryLower);
    const bStartsWith = defB.startsWith(queryLower);
    if (aStartsWith && !bStartsWith) return -1;
    if (!aStartsWith && bStartsWith) return 1;
    
    // Priority 2: Query is a standalone word (surrounded by spaces/punctuation)
    const wordBoundary = new RegExp(`(^|[\\s,;.!?])${queryLower}([\\s,;.!?]|$)`);
    const aStandalone = wordBoundary.test(defA);
    const bStandalone = wordBoundary.test(defB);
    if (aStandalone && !bStandalone) return -1;
    if (!aStandalone && bStandalone) return 1;
    
    // Priority 3: HSK level
    const hskA = a.h || 99;
    const hskB = b.h || 99;
    if (hskA !== hskB) return hskA - hskB;
    
    // Priority 4: Shorter word (more basic)
    return (a.w || '').length - (b.w || '').length;
  };
  
  chineseMatches.sort(sortByRelevance);
  pinyinExact.sort(sortByRelevance);
  pinyinStartsWith.sort(sortByRelevance);
  pinyinIncludes.sort(sortByRelevance);
  definitionMatches.sort(sortDefinitionsByRelevance);
  
  // Combine results in priority order
  const results = [
    ...chineseMatches,
    ...pinyinExact,
    ...pinyinStartsWith,
    ...pinyinIncludes,
    ...definitionMatches
  ].slice(0, limit);
  
  console.log(`[LaoshiDB] Found ${results.length} results`);
  return results;
  } catch (error) {
    console.error('[LaoshiDB] Search failed:', error);
    // Return empty array on error to prevent UI breakage
    return [];
  }
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
    icon: 'folder',
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
 * Clear all dictionary data
 */
async function clearDictionary() {
  try {
    console.log('[LaoshiDB] Clearing dictionary...');
    const database = await initDB();
    
    // Clear all stores
    const tx = database.transaction(['words', 'decks', 'deckWords'], 'readwrite');
    await tx.objectStore('words').clear();
    await tx.objectStore('decks').clear();
    await tx.objectStore('deckWords').clear();
    await tx.done;
    
    console.log('[LaoshiDB] Dictionary cleared successfully');
  } catch (error) {
    console.error('[LaoshiDB] Failed to clear dictionary:', error);
    throw new Error(`Failed to clear dictionary: ${error.message}`);
  }
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
  clearDictionary,
  getAvailableDictionaries,
  getCurrentDictionary,
  setCurrentDictionary,
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

