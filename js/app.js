/**
 * 老师词典 - Main Application
 * Framework7 initialization and UI logic
 */

// Initialize Framework7 App
const app = new Framework7({
  el: '#app',
  name: '老师词典',
  theme: 'ios',
  colors: {
    primary: '#e94560'
  },
  darkMode: false,
  touch: {
    tapHold: true
  },
  on: {
    init: async function() {
      await initializeApp();
    }
  }
});

// State
let searchTimeout = null;
let deckWordsVirtualList = null;
let currentDeckId = null;

/**
 * Initialize application
 */
async function initializeApp() {
  // Initialize database
  await LaoshiDB.initDB();
  
  // Load saved dark mode setting
  const darkMode = await LaoshiDB.getSetting('darkMode', false);
  if (darkMode) {
    app.setDarkMode(true);
    document.getElementById('toggle-dark-mode').checked = true;
  }
  
  // Load available dictionaries for settings
  await loadDictionaryList();
  
  // Check if dictionary is loaded
  const isLoaded = await LaoshiDB.isDictionaryLoaded();
  
  if (isLoaded) {
    showDictionaryReady();
  } else {
    showDictionaryInit();
  }
  
  // Load decks
  await loadDecks();
  
  // Update statistics
  await updateStats();
  
  // Setup event listeners
  setupEventListeners();
}

/**
 * Load and display available dictionaries in settings
 */
async function loadDictionaryList() {
  const index = await LaoshiDB.getAvailableDictionaries();
  const currentId = await LaoshiDB.getCurrentDictionary();
  const isLoaded = await LaoshiDB.isDictionaryLoaded();
  
  // Determine which dictionary is active
  const activeId = currentId || index.default;
  const activeDict = index.dictionaries.find(d => d.id === activeId);
  
  // Update current dictionary display in settings
  const currentName = document.getElementById('current-dictionary-name');
  const currentCount = document.getElementById('current-dictionary-count');
  
  if (currentName && activeDict) {
    currentName.textContent = activeDict.name;
  }
  
  if (currentCount && isLoaded) {
    const stats = await LaoshiDB.getStats();
    currentCount.textContent = `${stats.wordsCount.toLocaleString()} слов`;
  } else if (currentCount) {
    currentCount.textContent = 'не загружен';
  }
  
  // Update popup list
  const listContainer = document.getElementById('dictionary-list');
  if (!listContainer) return;
  
  if (index.dictionaries.length === 0) {
    listContainer.innerHTML = `
      <li>
        <div class="item-content">
          <div class="item-inner">
            <div class="item-title text-color-gray">Нет доступных словарей</div>
          </div>
        </div>
      </li>
    `;
    return;
  }
  
  listContainer.innerHTML = index.dictionaries.map(dict => {
    const isActive = dict.id === activeId && isLoaded;
    const checkmark = isActive ? '<i class="f7-icons text-color-primary">checkmark_alt</i>' : '';
    
    return `
      <li>
        <a href="#" class="item-link item-content dictionary-select-item" data-dict-id="${dict.id}" data-dict-file="${dict.file}" data-dict-name="${escapeHtml(dict.name)}">
          <div class="item-media">
            <i class="f7-icons">book</i>
          </div>
          <div class="item-inner">
            <div class="item-title">${escapeHtml(dict.name)}</div>
            <div class="item-after">${checkmark}</div>
          </div>
        </a>
      </li>
    `;
  }).join('');
}

/**
 * Switch to a different dictionary
 */
async function switchDictionary(dictionaryId, filePath, dictName) {
  // Close the popup first
  app.popup.close('#popup-select-dictionary');
  
  app.dialog.confirm(
    `Загрузить словарь "${dictName}"? Это заменит текущие данные.`,
    'Сменить словарь',
    async () => {
      // Show Framework7 preloader with progress
      app.dialog.preloader('Загрузка словаря...');
      
      try {
        // Save the selection
        await LaoshiDB.setCurrentDictionary(dictionaryId);
        
        // Load the new dictionary
        const count = await LaoshiDB.loadDictionary(filePath, (processed, total) => {
          const percent = Math.round((processed / total) * 100);
          // Update preloader text if dialog still open
          const preloaderText = document.querySelector('.dialog-preloader .dialog-title');
          if (preloaderText) {
            preloaderText.textContent = `Загрузка... ${percent}%`;
          }
        });
        
        app.dialog.close();
        
        app.toast.create({
          text: `Загружено ${count.toLocaleString()} слов`,
          closeTimeout: 2000
        }).open();
        
        showDictionaryReady();
        await loadDictionaryList();
        await updateStats();
      } catch (error) {
        console.error('Failed to load dictionary:', error);
        app.dialog.close();
        app.dialog.alert('Не удалось загрузить словарь', 'Ошибка');
      }
    }
  );
}

/**
 * Show dictionary initialization screen
 */
function showDictionaryInit() {
  document.getElementById('dictionary-init').style.display = 'block';
  document.getElementById('dictionary-loading').style.display = 'none';
  document.getElementById('search-empty').style.display = 'none';
  document.querySelector('.search-results').style.display = 'none';
}

/**
 * Show dictionary ready state
 */
function showDictionaryReady() {
  document.getElementById('dictionary-init').style.display = 'none';
  document.getElementById('dictionary-loading').style.display = 'none';
  document.getElementById('search-empty').style.display = 'block';
  document.querySelector('.search-results').style.display = 'none';
}

/**
 * Show loading state
 */
function showLoading(message = 'Загрузка...') {
  document.getElementById('dictionary-init').style.display = 'none';
  document.getElementById('dictionary-loading').style.display = 'block';
  document.getElementById('dictionary-loading').querySelector('p').textContent = message;
  document.getElementById('search-empty').style.display = 'none';
}

/**
 * Load dictionary from file
 */
async function loadDictionary() {
  showLoading('Загрузка словаря...');
  
  try {
    const count = await LaoshiDB.loadDictionary((processed, total) => {
      const percent = Math.round((processed / total) * 100);
      document.getElementById('dictionary-loading').querySelector('p').textContent = 
        `Загружено ${processed} из ${total} слов (${percent}%)`;
    });
    
    app.toast.create({
      text: `Загружено ${count} слов`,
      closeTimeout: 2000
    }).open();
    
    showDictionaryReady();
    await loadDecks();
    await updateStats();
  } catch (error) {
    console.error('Failed to load dictionary:', error);
    app.dialog.alert('Не удалось загрузить словарь. Проверьте подключение к интернету.', 'Ошибка');
    showDictionaryInit();
  }
}

/**
 * Perform search
 */
async function performSearch(query) {
  const resultsContainer = document.querySelector('.search-results');
  const resultsList = document.getElementById('search-results-list');
  const emptyState = document.getElementById('search-empty');
  const noResults = document.getElementById('search-no-results');
  
  if (!query || query.length < 1) {
    resultsContainer.style.display = 'none';
    emptyState.style.display = 'block';
    noResults.style.display = 'none';
    return;
  }
  
  emptyState.style.display = 'none';
  
  const results = await LaoshiDB.searchWords(query);
  
  if (results.length === 0) {
    resultsContainer.style.display = 'none';
    noResults.style.display = 'block';
    return;
  }
  
  noResults.style.display = 'none';
  resultsContainer.style.display = 'block';
  
  // Render results
  resultsList.innerHTML = results.map(word => {
    const definition = Array.isArray(word.d) ? word.d[0] : word.d;
    
    return `
      <li>
        <a href="#" class="item-link item-content word-item" data-word='${JSON.stringify(word).replace(/'/g, "&#39;")}'>
          <div class="item-inner">
            <div class="item-title-row">
              <div class="item-title"><span class="chinese">${escapeHtml(word.w)}</span> <span class="pinyin">${escapeHtml(LaoshiPinyin.convert(word.p || ''))}</span></div>
            </div>
            <div class="item-text russian">${escapeHtml(truncateText(definition, 150))}</div>
          </div>
        </a>
      </li>
    `;
  }).join('');
}

/**
 * Load and display decks
 */
async function loadDecks() {
  const decks = await LaoshiDB.getAllDecks();
  
  const systemDecks = decks.filter(d => d.type === 'system');
  const userDecks = decks.filter(d => d.type === 'user');
  
  // Render system decks
  const systemList = document.querySelector('#system-decks-list ul');
  systemList.innerHTML = systemDecks.map(deck => {
    const iconClass = deck.id === 'favorites' ? 'favorites' : 'hsk';
    return `
      <li>
        <a href="#" class="item-link item-content deck-item ${iconClass}" data-deck-id="${deck.id}">
          <div class="item-media">
            <i class="f7-icons">${deck.icon || 'folder'}</i>
          </div>
          <div class="item-inner">
            <div class="item-title">${escapeHtml(deck.name)}</div>
            <div class="item-after">${deck.count || 0}</div>
          </div>
        </a>
      </li>
    `;
  }).join('');
  
  // Render user decks
  const userList = document.querySelector('#user-decks-list ul');
  if (userDecks.length === 0) {
    userList.innerHTML = `
      <li class="item-content" id="no-user-decks">
        <div class="item-inner">
          <div class="item-title text-color-gray">Нет пользовательских списков</div>
        </div>
      </li>
    `;
  } else {
    userList.innerHTML = userDecks.map(deck => `
      <li class="swipeout">
        <a href="#" class="item-link item-content deck-item swipeout-content" data-deck-id="${deck.id}">
          <div class="item-media">
            <i class="f7-icons">${deck.icon || 'folder'}</i>
          </div>
          <div class="item-inner">
            <div class="item-title">${escapeHtml(deck.name)}</div>
            <div class="item-after">${deck.count || 0}</div>
          </div>
        </a>
        <div class="swipeout-actions-right">
          <a href="#" class="swipeout-delete" data-confirm="Удалить список?" data-deck-id="${deck.id}">Удалить</a>
        </div>
      </li>
    `).join('');
  }
}

/**
 * Open deck and show words
 */
async function openDeck(deckId) {
  currentDeckId = deckId;
  const deck = await LaoshiDB.getDeck(deckId);
  
  if (!deck) {
    app.dialog.alert('Список не найден', 'Ошибка');
    return;
  }
  
  document.getElementById('popup-deck-title').textContent = deck.name;
  
  // Load words
  let words = [];
  
  if (deck.file) {
    // HSK deck - lazy load
    app.preloader.show();
    words = await LaoshiDB.loadHSKDeck(deckId);
    app.preloader.hide();
  } else {
    words = await LaoshiDB.getDeckWords(deckId);
  }
  
  // Create virtual list
  const container = document.getElementById('deck-words-list');
  container.innerHTML = '';
  
  if (words.length === 0) {
    container.innerHTML = `
      <div class="block text-align-center">
        <i class="f7-icons" style="font-size: 64px; opacity: 0.5;">doc_text</i>
        <p>Список пуст</p>
      </div>
    `;
  } else {
    // Destroy previous virtual list if exists
    if (deckWordsVirtualList) {
      deckWordsVirtualList.destroy();
    }
    
    // Convert pinyin to tonal
    const itemsWithTonalPinyin = words.map(w => ({
      ...w,
      pinyin: LaoshiPinyin.convert(w.pinyin || '')
    }));
    
    // Create new virtual list
    deckWordsVirtualList = app.virtualList.create({
      el: container,
      items: itemsWithTonalPinyin,
      itemTemplate: `
        <li>
          <div class="item-content">
            <div class="item-inner">
              <div class="item-title-row">
                <div class="item-title chinese">{{word}}</div>
              </div>
              <div class="item-subtitle pinyin">{{pinyin}}</div>
              <div class="item-text russian">{{translation}}</div>
            </div>
          </div>
        </li>
      `,
      height: 80
    });
  }
  
  // Open popup
  app.popup.open('#popup-deck-words');
  
  // Reload decks to update count
  await loadDecks();
}

/**
 * Create new user deck
 */
async function createNewDeck() {
  const input = document.getElementById('input-deck-name');
  const name = input.value.trim();
  
  if (!name) {
    app.dialog.alert('Введите название списка', 'Ошибка');
    return;
  }
  
  await LaoshiDB.createDeck(name);
  input.value = '';
  
  app.popup.close('#popup-add-deck');
  await loadDecks();
  
  app.toast.create({
    text: 'Список создан',
    closeTimeout: 2000
  }).open();
}

/**
 * Delete user deck
 */
async function deleteUserDeck(deckId) {
  await LaoshiDB.deleteDeck(deckId);
  await loadDecks();
  
  app.toast.create({
    text: 'Список удалён',
    closeTimeout: 2000
  }).open();
}

/**
 * Update statistics
 */
async function updateStats() {
  const stats = await LaoshiDB.getStats();
  
  document.getElementById('stats-words-count').textContent = stats.wordsCount.toLocaleString();
  document.getElementById('stats-decks-count').textContent = stats.decksCount;
  document.getElementById('stats-db-size').textContent = stats.dbSize;
}

/**
 * Toggle dark mode
 */
async function toggleDarkMode(enabled) {
  // Framework7 v9+ uses setDarkMode() instead of darkMode.enable()/disable()
  app.setDarkMode(enabled);
  await LaoshiDB.setSetting('darkMode', enabled);
}

// Current word for popup
let currentPopupWord = null;
let wordDetailsPopup = null;

/**
 * Show word details with option to add to favorites
 */
function showWordDetails(word) {
  currentPopupWord = word;
  
  const definitions = Array.isArray(word.d) ? word.d : [word.d];
  const hskBadge = word.h ? `<span class="badge">${word.h}</span>` : '';
  
  // Populate popup content
  document.getElementById('popup-word-title').innerHTML = escapeHtml(word.w) + hskBadge;
  document.getElementById('popup-word-chinese').textContent = word.w;
  document.getElementById('popup-word-pinyin').textContent = LaoshiPinyin.convert(word.p || '');
  
  // Populate definitions block
  const definitionsBlock = document.getElementById('popup-word-definitions');
  definitionsBlock.innerHTML = definitions.map(def => 
    `<p class="russian">${escapeHtml(def)}</p>`
  ).join('');
  
  // Create popup with swipe-to-close and push animation (iOS style)
  if (!wordDetailsPopup) {
    wordDetailsPopup = app.popup.create({
      el: '#popup-word-details',
      swipeToClose: true,
      push: true
    });
  }
  
  wordDetailsPopup.open();
}

/**
 * Setup event listeners
 */
function setupEventListeners() {
  // Load dictionary button
  document.getElementById('btn-load-dictionary').addEventListener('click', loadDictionary);
  
  // Initialize Framework7 Searchbar
  app.searchbar.create({
    el: '#searchbar-dictionary',
    customSearch: true,
    disableButton: false,
    on: {
      search(sb, query) {
        clearTimeout(searchTimeout);
        searchTimeout = setTimeout(() => {
          performSearch(query.trim());
        }, 300);
      },
      clear() {
        performSearch('');
      },
      disable() {
        performSearch('');
      }
    }
  });
  
  // Word item click (search results)
  document.getElementById('search-results-list').addEventListener('click', (e) => {
    const wordItem = e.target.closest('.word-item');
    if (wordItem) {
      e.preventDefault();
      const word = JSON.parse(wordItem.dataset.word);
      showWordDetails(word);
    }
  });
  
  // Deck item click
  document.addEventListener('click', (e) => {
    const deckItem = e.target.closest('.deck-item');
    if (deckItem && !e.target.closest('.swipeout-actions-right')) {
      e.preventDefault();
      openDeck(deckItem.dataset.deckId);
    }
  });
  
  // Delete deck
  document.addEventListener('click', (e) => {
    const deleteBtn = e.target.closest('.swipeout-delete[data-deck-id]');
    if (deleteBtn) {
      const deckId = deleteBtn.dataset.deckId;
      deleteUserDeck(deckId);
    }
  });
  
  // Add deck button
  document.getElementById('btn-add-deck').addEventListener('click', () => {
    app.popup.open('#popup-add-deck');
  });
  
  // Save deck button
  document.getElementById('btn-save-deck').addEventListener('click', createNewDeck);
  
  // Dark mode toggle
  document.getElementById('toggle-dark-mode').addEventListener('change', (e) => {
    toggleDarkMode(e.target.checked);
  });
  
  // Popup favorite button
  document.getElementById('btn-popup-favorite').addEventListener('click', async () => {
    if (currentPopupWord) {
      const added = await LaoshiDB.toggleFavorite(currentPopupWord);
      app.toast.create({
        text: added ? 'Добавлено в избранное' : 'Удалено из избранного',
        closeTimeout: 1500
      }).open();
      await loadDecks();
    }
  });
  
  // Tab change - update stats when settings tab is shown
  document.querySelectorAll('.tab-link').forEach(tab => {
    tab.addEventListener('click', async () => {
      if (tab.getAttribute('href') === '#view-settings') {
        await updateStats();
        await loadDictionaryList();
      }
    });
  });
  
  // Open dictionary selection popup
  document.getElementById('btn-select-dictionary').addEventListener('click', (e) => {
    e.preventDefault();
    app.popup.open('#popup-select-dictionary');
  });
  
  // Dictionary selection in popup
  document.getElementById('dictionary-list').addEventListener('click', (e) => {
    const dictItem = e.target.closest('.dictionary-select-item');
    if (dictItem) {
      e.preventDefault();
      const dictId = dictItem.dataset.dictId;
      const dictFile = dictItem.dataset.dictFile;
      const dictName = dictItem.dataset.dictName;
      switchDictionary(dictId, dictFile, dictName);
    }
  });
}

/**
 * Utility: Escape HTML
 */
function escapeHtml(text) {
  if (!text) return '';
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

/**
 * Utility: Truncate text
 */
function truncateText(text, maxLength) {
  if (!text) return '';
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength) + '...';
}
