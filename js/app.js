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

// Application State Management
const AppState = {
  searchTimeout: null,
  deckWordsVirtualList: null,
  currentDeckId: null,
  currentPopupWord: null,
  wordDetailsPopup: null,
  
  // Clear search timeout
  clearSearchTimeout() {
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout);
      this.searchTimeout = null;
    }
  },
  
  // Clear virtual list
  clearVirtualList() {
    if (this.deckWordsVirtualList) {
      this.deckWordsVirtualList.destroy();
      this.deckWordsVirtualList = null;
    }
  },
  
  // Reset deck state
  resetDeckState() {
    this.clearVirtualList();
    this.currentDeckId = null;
  },
  
  // Reset word popup state
  resetWordPopupState() {
    this.currentPopupWord = null;
  },
  
  // Full state reset (for tab switches)
  reset() {
    this.clearSearchTimeout();
    this.resetDeckState();
  }
};

/**
 * Unified UI state management for dictionary view
 * @param {string} state - One of: 'init', 'loading', 'ready', 'searching'
 * @param {string} message - Optional message for loading state
 */
function setDictionaryViewState(state, message = 'Загрузка...') {
  console.log(`[App] Setting dictionary view state: ${state}`);
  
  const initEl = document.getElementById('dictionary-init');
  const loadingEl = document.getElementById('dictionary-loading');
  const emptyEl = document.getElementById('search-empty');
  const resultsEl = document.querySelector('.search-results');
  const noResultsEl = document.getElementById('search-no-results');
  
  // Hide all states
  initEl.style.display = 'none';
  loadingEl.style.display = 'none';
  emptyEl.style.display = 'none';
  resultsEl.style.display = 'none';
  noResultsEl.style.display = 'none';
  
  // Show appropriate state
  switch (state) {
    case 'init':
      initEl.style.display = 'block';
      break;
    case 'loading':
      loadingEl.style.display = 'block';
      loadingEl.querySelector('p').textContent = message;
      break;
    case 'ready':
      emptyEl.style.display = 'block';
      break;
    case 'searching':
      // Results will be shown by performSearch
      break;
    default:
      console.warn(`[App] Unknown dictionary view state: ${state}`);
      emptyEl.style.display = 'block';
  }
}

/**
 * Initialize application
 */
async function initializeApp() {
  try {
    console.log('[App] Initializing application...');
    
    // Initialize database
    try {
      await LaoshiDB.initDB();
    } catch (error) {
      console.error('[App] Database initialization failed:', error);
      app.dialog.alert(
        'Не удалось инициализировать базу данных. Попробуйте перезагрузить страницу.',
        'Ошибка базы данных'
      );
      return;
    }
    
    // Load saved dark mode setting
    try {
      const darkMode = await LaoshiDB.getSetting('darkMode', false);
      if (darkMode) {
        app.setDarkMode(true);
        const toggle = document.getElementById('toggle-dark-mode');
        if (toggle) toggle.checked = true;
      }
    } catch (error) {
      console.error('[App] Failed to load dark mode setting:', error);
      // Non-critical, continue
    }
    
    // Load available dictionaries for settings
    try {
      await loadDictionaryList();
    } catch (error) {
      console.error('[App] Failed to load dictionary list:', error);
      // Non-critical, continue
    }
    
    // Check if dictionary is loaded
    try {
      const isLoaded = await LaoshiDB.isDictionaryLoaded();
      
      if (isLoaded) {
        setDictionaryViewState('ready');
      } else {
        setDictionaryViewState('init');
      }
    } catch (error) {
      console.error('[App] Failed to check dictionary status:', error);
      setDictionaryViewState('init');
    }
    
    // Load decks
    try {
      await loadDecks();
    } catch (error) {
      console.error('[App] Failed to load decks:', error);
      // Non-critical, continue
    }
    
    // Update statistics
    try {
      await updateStats();
    } catch (error) {
      console.error('[App] Failed to update stats:', error);
      // Non-critical, continue
    }
    
    // Setup event listeners
    try {
      setupEventListeners();
    } catch (error) {
      console.error('[App] Failed to setup event listeners:', error);
      app.dialog.alert(
        'Произошла ошибка при настройке интерфейса. Попробуйте перезагрузить страницу.',
        'Ошибка'
      );
    }
    
    console.log('[App] Application initialized successfully');
  } catch (error) {
    console.error('[App] Critical error during initialization:', error);
    app.dialog.alert(
      'Произошла критическая ошибка. Попробуйте перезагрузить страницу.',
      'Критическая ошибка'
    );
  }
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
  const nameEl = document.getElementById('current-dictionary-name');
  const statusEl = document.getElementById('current-dictionary-status');
  
  if (nameEl && activeDict) {
    nameEl.textContent = activeDict.name;
  } else if (nameEl) {
    nameEl.textContent = 'Не выбран';
  }
  
  if (statusEl) {
    if (isLoaded) {
      const stats = await LaoshiDB.getStats();
      statusEl.textContent = `${stats.wordsCount.toLocaleString()} слов`;
    } else {
      statusEl.textContent = 'не загружен';
    }
  }
  
  // Update radio list in popup
  const radioList = document.getElementById('dictionary-radio-list');
  if (!radioList) return;
  
  if (index.dictionaries.length === 0) {
    radioList.innerHTML = `
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
  
  radioList.innerHTML = index.dictionaries.map((dict, idx) => {
    const isActive = dict.id === activeId;
    return `
      <li>
        <label class="item-radio item-content">
          <input type="radio" name="dictionary-radio" value="${dict.id}" data-dict-file="${dict.file}" ${isActive ? 'checked' : ''}>
          <i class="icon icon-radio"></i>
          <div class="item-inner">
            <div class="item-title">${escapeHtml(dict.name)}</div>
          </div>
        </label>
      </li>
    `;
  }).join('');
}

/**
 * Load dictionary from file
 */
async function loadDictionary() {
  setDictionaryViewState('loading', 'Загрузка словаря...');
  
  try {
    const count = await LaoshiDB.loadDictionary((processed, total) => {
      const percent = Math.round((processed / total) * 100);
      setDictionaryViewState('loading', `Загружено ${processed} из ${total} слов (${percent}%)`);
    });
    
    app.toast.create({
      text: `Загружено ${count} слов`,
      closeTimeout: 2000
    }).open();
    
    setDictionaryViewState('ready');
    await loadDecks();
    await updateStats();
  } catch (error) {
    console.error('[App] Failed to load dictionary:', error);
    app.dialog.alert('Не удалось загрузить словарь. Проверьте подключение к интернету.', 'Ошибка');
    setDictionaryViewState('init');
  }
}

/**
 * Perform search
 */
async function performSearch(query) {
  try {
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
    
    // Perform search with error handling
    let results;
    try {
      results = await LaoshiDB.searchWords(query);
    } catch (error) {
      console.error('[App] Search failed:', error);
      app.toast.create({
        text: 'Ошибка поиска. Попробуйте снова.',
        closeTimeout: 2000
      }).open();
      resultsContainer.style.display = 'none';
      emptyState.style.display = 'block';
      return;
    }
    
    if (results.length === 0) {
      resultsContainer.style.display = 'none';
      noResults.style.display = 'block';
      return;
    }
    
    noResults.style.display = 'none';
    resultsContainer.style.display = 'block';
    
    // Render results
    try {
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
    } catch (error) {
      console.error('[App] Failed to render search results:', error);
      app.toast.create({
        text: 'Ошибка отображения результатов',
        closeTimeout: 2000
      }).open();
    }
  } catch (error) {
    console.error('[App] Unexpected error in performSearch:', error);
  }
}

/**
 * Load and display decks
 */
async function loadDecks() {
  try {
    console.log('[App] Loading decks...');
    const decks = await LaoshiDB.getAllDecks();
    
    const systemDecks = decks.filter(d => d.type === 'system');
    const userDecks = decks.filter(d => d.type === 'user');
    
    // Render system decks
    try {
      const systemList = document.querySelector('#system-decks-list ul');
      if (systemList) {
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
      }
    } catch (error) {
      console.error('[App] Failed to render system decks:', error);
    }
    
    // Render user decks
    try {
      const userList = document.querySelector('#user-decks-list ul');
      if (userList) {
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
    } catch (error) {
      console.error('[App] Failed to render user decks:', error);
    }
    
    console.log('[App] Decks loaded successfully');
  } catch (error) {
    console.error('[App] Failed to load decks:', error);
    throw error;
  }
}

/**
 * Open deck and show words
 */
async function openDeck(deckId) {
  try {
    AppState.currentDeckId = deckId;
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
      try {
        words = await LaoshiDB.loadHSKDeck(deckId);
      } catch (error) {
        console.error('[App] Failed to load HSK deck:', error);
        app.preloader.hide();
        app.toast.create({
          text: 'Не удалось загрузить список',
          closeTimeout: 2000
        }).open();
        return;
      }
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
      AppState.clearVirtualList();
      
      // Convert pinyin to tonal
      const itemsWithTonalPinyin = words.map(w => ({
        ...w,
        pinyin: LaoshiPinyin.convert(w.pinyin || '')
      }));
      
      // Create new virtual list
      AppState.deckWordsVirtualList = app.virtualList.create({
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
  } catch (error) {
    console.error('[App] Failed to open deck:', error);
    app.toast.create({
      text: 'Ошибка при открытии списка',
      closeTimeout: 2000
    }).open();
  }
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

/**
 * Show word details with option to add to favorites
 */
function showWordDetails(word) {
  AppState.currentPopupWord = word;
  
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
  if (!AppState.wordDetailsPopup) {
    AppState.wordDetailsPopup = app.popup.create({
      el: '#popup-word-details',
      swipeToClose: true,
      push: true
    });
  }
  
  AppState.wordDetailsPopup.open();
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
        AppState.clearSearchTimeout();
        AppState.searchTimeout = setTimeout(() => {
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
    if (AppState.currentPopupWord) {
      const added = await LaoshiDB.toggleFavorite(AppState.currentPopupWord);
      app.toast.create({
        text: added ? 'Добавлено в избранное' : 'Удалено из избранного',
        closeTimeout: 1500
      }).open();
      await loadDecks();
    }
  });
  
  // Tab change - update stats when settings tab is shown and cleanup state
  document.querySelectorAll('.tab-link').forEach(tab => {
    tab.addEventListener('click', async () => {
      const href = tab.getAttribute('href');
      
      // Cleanup state on tab switch
      if (href !== '#view-dictionary') {
        AppState.clearSearchTimeout();
      }
      
      if (href === '#view-settings') {
        await updateStats();
        await loadDictionaryList();
      }
    });
  });
  
  // Open dictionary selection sheet
  document.getElementById('btn-open-dictionary-popup')?.addEventListener('click', (e) => {
    e.preventDefault();
    app.sheet.open('#sheet-dictionary-select');
  });
  
  // Load selected dictionary button
  document.getElementById('btn-load-selected-dictionary')?.addEventListener('click', async () => {
    const selected = document.querySelector('input[name="dictionary-radio"]:checked');
    if (!selected) {
      app.dialog.alert('Выберите словарь из списка');
      return;
    }
    
    const dictId = selected.value;
    const dictFile = selected.dataset.dictFile;
    const dictName = selected.closest('li').querySelector('.item-title').textContent;
    
    app.sheet.close('#sheet-dictionary-select');
    
    // Load the dictionary with progress
    app.dialog.preloader('Загрузка словаря...');
    try {
      await LaoshiDB.setCurrentDictionary(dictId);
      const count = await LaoshiDB.loadDictionary(dictFile, (processed, total) => {
        const percent = Math.round((processed / total) * 100);
        const preloaderText = document.querySelector('.dialog-preloader .dialog-title');
        if (preloaderText) {
          preloaderText.textContent = `Загрузка... ${percent}%`;
        }
      });
      app.dialog.close();
      app.toast.create({ text: `Загружено ${count.toLocaleString()} слов`, closeTimeout: 2000 }).open();
      setDictionaryViewState('ready');
      await loadDictionaryList();
      await updateStats();
    } catch (error) {
      app.dialog.close();
      app.dialog.alert(`Ошибка загрузки: ${error.message}`);
    }
  });
  
  // Clear dictionaries button
  document.getElementById('btn-clear-dictionaries')?.addEventListener('click', () => {
    app.dialog.confirm(
      'Удалить все загруженные словари? Это очистит базу данных.',
      'Очистить словари',
      async () => {
        app.sheet.close('#sheet-dictionary-select');
        app.dialog.preloader('Очистка...');
        try {
          await LaoshiDB.clearDictionary();
          app.dialog.close();
          app.toast.create({ text: 'Словари очищены', closeTimeout: 2000 }).open();
          await loadDictionaryList();
          await updateStats();
        } catch (error) {
          app.dialog.close();
          app.dialog.alert(`Ошибка: ${error.message}`);
        }
      }
    );
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

/**
 * Export public API
 * These functions can be called from external scripts or console for debugging
 */
window.LaoshiApp = {
  // State management
  AppState,
  
  // UI state control
  setDictionaryViewState,
  
  // Core functions
  loadDictionary,
  performSearch,
  loadDecks,
  updateStats,
  
  // Utility functions
  escapeHtml,
  truncateText
};
