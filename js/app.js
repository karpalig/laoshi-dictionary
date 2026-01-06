/**
 * 老师词典 - Main Application
 * Framework7 initialization and UI logic
 */

// #region agent log
fetch('http://127.0.0.1:7243/ingest/45da4037-6012-4729-a16c-95ef8335a1bc',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'app.js:1',message:'Script loaded, before F7 init',data:{f7Exists:typeof Framework7,tabbarEl:!!document.querySelector('.tabbar')},timestamp:Date.now(),sessionId:'debug-session',hypothesisId:'A'})}).catch(()=>{});
// #endregion

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
      // #region agent log
      fetch('http://127.0.0.1:7243/ingest/45da4037-6012-4729-a16c-95ef8335a1bc',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'app.js:init',message:'F7 init callback fired',data:{appEl:!!document.getElementById('app'),tabbarVisible:document.querySelector('.tabbar')?.offsetHeight>0,tabbarDisplay:getComputedStyle(document.querySelector('.tabbar')||document.body).display},timestamp:Date.now(),sessionId:'debug-session',hypothesisId:'A,C'})}).catch(()=>{});
      // #endregion
      console.log('App initialized');
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
  // #region agent log
  const tabbar = document.querySelector('.tabbar');
  const views = document.querySelector('.views');
  fetch('http://127.0.0.1:7243/ingest/45da4037-6012-4729-a16c-95ef8335a1bc',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'app.js:initializeApp',message:'initializeApp started',data:{tabbarExists:!!tabbar,tabbarParent:tabbar?.parentElement?.id,viewsClasses:views?.className,tabbarRect:tabbar?.getBoundingClientRect()},timestamp:Date.now(),sessionId:'debug-session',hypothesisId:'B,D,E'})}).catch(()=>{});
  // #endregion
  
  // Initialize database
  await LaoshiDB.initDB();
  
  // Load saved dark mode setting
  const darkMode = await LaoshiDB.getSetting('darkMode', false);
  if (darkMode) {
    app.darkMode.enable();
    document.getElementById('toggle-dark-mode').checked = true;
  }
  
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
    const hskBadge = word.h ? `<span class="hsk-badge">HSK ${word.h}</span>` : '';
    
    return `
      <li>
        <a href="#" class="item-link item-content word-item" data-word='${JSON.stringify(word).replace(/'/g, "&#39;")}'>
          <div class="item-inner">
            <div class="item-title-row">
              <div class="item-title chinese">${escapeHtml(word.w)}${hskBadge}</div>
            </div>
            <div class="item-subtitle pinyin">${escapeHtml(word.p || '')}</div>
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
            <i class="f7-icons">${deck.icon || 'folder_fill'}</i>
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
            <i class="f7-icons">${deck.icon || 'folder_fill'}</i>
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
    
    // Create new virtual list
    deckWordsVirtualList = app.virtualList.create({
      el: container,
      items: words,
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
  if (enabled) {
    app.darkMode.enable();
  } else {
    app.darkMode.disable();
  }
  
  await LaoshiDB.setSetting('darkMode', enabled);
}

/**
 * Show word details with option to add to favorites
 */
function showWordDetails(word) {
  const definition = Array.isArray(word.d) ? word.d.join('\n\n') : word.d;
  const hskInfo = word.h ? `HSK ${word.h}` : '';
  
  app.dialog.create({
    title: word.w,
    text: `<div class="pinyin">${escapeHtml(word.p || '')}</div>
           ${hskInfo ? `<div class="hsk-badge" style="margin: 8px 0;">${hskInfo}</div>` : ''}
           <div class="russian" style="margin-top: 12px; text-align: left; white-space: pre-wrap;">${escapeHtml(definition)}</div>`,
    buttons: [
      {
        text: '⭐ В избранное',
        onClick: async () => {
          const added = await LaoshiDB.toggleFavorite(word);
          app.toast.create({
            text: added ? 'Добавлено в избранное' : 'Удалено из избранного',
            closeTimeout: 1500
          }).open();
          await loadDecks();
        }
      },
      {
        text: 'Закрыть',
        bold: true
      }
    ]
  }).open();
}

/**
 * Setup event listeners
 */
function setupEventListeners() {
  // Load dictionary button
  document.getElementById('btn-load-dictionary').addEventListener('click', loadDictionary);
  
  // Search input
  const searchInput = document.getElementById('search-input');
  searchInput.addEventListener('input', (e) => {
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(() => {
      performSearch(e.target.value.trim());
    }, 300);
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
  
  // Tab change - update stats when settings tab is shown
  document.querySelectorAll('.tab-link').forEach(tab => {
    tab.addEventListener('click', async () => {
      if (tab.getAttribute('href') === '#view-settings') {
        await updateStats();
      }
    });
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

