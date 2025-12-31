// Main Application Controller
const app = {
    currentTab: 'search',
    dictionaries: [],
    words: [],
    searchResults: [],
    favoriteWords: [],

    async init() {
        try {
            // Initialize database
            await db.init();
            
            // Load initial data
            await this.loadData();
            
            // Setup event listeners
            this.setupEventListeners();
            
            // Hide loading, show app
            document.getElementById('loading-screen').classList.add('hidden');
            document.getElementById('main-app').classList.remove('hidden');
            
            // Render initial view
            this.renderSearch();
        } catch (error) {
            console.error('App initialization failed:', error);
            alert('Ошибка инициализации приложения. Пожалуйста, перезагрузите страницу.');
        }
    },

    async loadData() {
        this.dictionaries = await db.getAllDictionaries();
        this.words = await db.getAllWords();
        this.favoriteWords = await db.getFavoriteWords();
    },

    setupEventListeners() {
        const searchInput = document.getElementById('search-input');
        searchInput.addEventListener('input', (e) => {
            this.handleSearch(e.target.value);
        });
    },

    // Tab switching
    switchTab(tabName) {
        this.currentTab = tabName;
        
        // Update nav items
        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.remove('active');
            if (item.dataset.tab === tabName) {
                item.classList.add('active');
            }
        });
        
        // Update tab panes
        document.querySelectorAll('.tab-pane').forEach(pane => {
            pane.classList.remove('active');
        });
        document.getElementById(`${tabName}-tab`).classList.add('active');
        
        // Render content
        switch (tabName) {
            case 'search':
                this.renderSearch();
                break;
            case 'dictionaries':
                this.renderDictionaries();
                break;
            case 'favorites':
                this.renderFavorites();
                break;
        }
    },

    // Search functionality
    handleSearch(query) {
        if (!query.trim()) {
            this.searchResults = [];
            this.renderSearch();
            return;
        }

        const normalizedQuery = PinyinHelper.normalizeForSearch(query);
        
        this.searchResults = this.words.filter(word => {
            const normalizedChinese = word.chinese.toLowerCase();
            const normalizedPinyin = PinyinHelper.normalizeForSearch(word.pinyin);
            const normalizedRussian = word.russian.toLowerCase();
            
            return normalizedChinese.includes(normalizedQuery) ||
                   normalizedPinyin.includes(normalizedQuery) ||
                   normalizedRussian.includes(normalizedQuery);
        });
        
        this.renderSearch();
    },

    // Render functions
    renderSearch() {
        const container = document.getElementById('search-results');
        const query = document.getElementById('search-input').value;
        const words = query ? this.searchResults : this.words.slice(0, 10);

        if (words.length === 0) {
            if (query) {
                container.innerHTML = this.getEmptyState('search_off', 'Ничего не найдено', 'Попробуйте другой запрос');
            } else {
                container.innerHTML = this.getEmptyState('book_outlined', 'Словарь пуст', 'Добавьте слова в словарь', true);
            }
            return;
        }

        const title = query ? `Результаты поиска (${words.length})` : 'Недавние слова';
        
        container.innerHTML = `
            <div class="results-header" style="padding: 10px 0; font-size: 18px; font-weight: 600; color: rgba(255,255,255,0.9);">
                ${title}
            </div>
            ${words.map(word => this.createWordCard(word)).join('')}
        `;
    },

    renderDictionaries() {
        const container = document.getElementById('dictionaries-list');
        
        if (this.dictionaries.length === 0) {
            container.innerHTML = this.getEmptyState('book', 'Нет словарей', 'Создайте свой первый словарь');
            return;
        }

        container.innerHTML = this.dictionaries.map(dict => this.createDictionaryCard(dict)).join('');
    },

    async renderFavorites() {
        this.favoriteWords = await db.getFavoriteWords();
        const container = document.getElementById('favorites-list');
        
        if (this.favoriteWords.length === 0) {
            container.innerHTML = this.getEmptyState('star_border', 'Нет избранных слов', 'Добавьте слова в избранное');
            return;
        }

        container.innerHTML = this.favoriteWords.map(word => this.createWordCard(word)).join('');
    },

    // Card creators
    createWordCard(word) {
        const dict = this.dictionaries.find(d => d.id === word.dictionaryId);
        const hskBadge = word.hskLevel > 0 ? `<span class="hsk-badge">HSK ${word.hskLevel}</span>` : '';
        const dictName = dict ? `<span class="meta-text">${dict.name}</span>` : '';
        const favoriteIcon = word.isFavorite ? '⭐' : '☆';

        return `
            <div class="word-card" onclick="app.showWordDetail('${word.id}')">
                <div class="word-card-header">
                    <div class="word-info">
                        <h3 class="chinese">${word.chinese}</h3>
                        <div class="word-pinyin">${word.pinyin}</div>
                    </div>
                    <button class="favorite-btn" onclick="event.stopPropagation(); app.toggleFavorite('${word.id}')">
                        ${favoriteIcon}
                    </button>
                </div>
                <div class="word-translation">${word.russian}</div>
                <div class="word-meta">
                    ${hskBadge}
                    ${dictName}
                </div>
            </div>
        `;
    },

    createDictionaryCard(dict) {
        const wordsCount = this.words.filter(w => w.dictionaryId === dict.id).length;
        const activeIcon = dict.isActive ? '✓' : '○';
        const colorStyle = `background-color: ${this.getColorValue(dict.color)}`;

        return `
            <div class="dict-card" onclick="app.showDictionaryDetail('${dict.id}')">
                <div class="dict-icon" style="${colorStyle}">
                    📚
                </div>
                <div class="dict-info">
                    <h3>${dict.name}</h3>
                    ${dict.description ? `<div class="dict-description">${dict.description}</div>` : ''}
                    <div class="dict-count">${wordsCount} слов</div>
                </div>
                <div class="dict-active" onclick="event.stopPropagation(); app.toggleDictionaryActive('${dict.id}')">
                    ${activeIcon}
                </div>
            </div>
        `;
    },

    getEmptyState(icon, title, subtitle, showButton = false) {
        const button = showButton ? '<button class="glass-button" onclick="app.createSampleData()">Загрузить примеры</button>' : '';
        
        return `
            <div class="empty-state">
                <svg width="60" height="60" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    ${this.getIconPath(icon)}
                </svg>
                <h3>${title}</h3>
                <p>${subtitle}</p>
                ${button}
            </div>
        `;
    },

    getIconPath(name) {
        const icons = {
            'search_off': '<path d="M11 19a8 8 0 1 0 0-16 8 8 0 0 0 0 16z M21 21l-4-4"/>',
            'book_outlined': '<path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20M4 19.5A2.5 2.5 0 0 0 6.5 22H20V2H6.5A2.5 2.5 0 0 0 4 4.5v15z"/>',
            'book': '<path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20M4 19.5A2.5 2.5 0 0 0 6.5 22H20V2H6.5A2.5 2.5 0 0 0 4 4.5v15z"/>',
            'star_border': '<path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>'
        };
        return icons[name] || '';
    },

    // Modals and forms
    showAddDictionary() {
        this.showModal('Новый словарь', this.getAddDictionaryForm());
    },

    getAddDictionaryForm() {
        return `
            <form onsubmit="event.preventDefault(); app.handleAddDictionary();" id="dict-form">
                <div class="form-group">
                    <label>Название словаря</label>
                    <input type="text" id="dict-name" required>
                </div>
                <div class="form-group">
                    <label>Описание</label>
                    <textarea id="dict-description"></textarea>
                </div>
                <div class="form-group">
                    <label>Цвет</label>
                    <div class="color-picker">
                        ${['cyan', 'blue', 'purple', 'pink', 'green', 'orange'].map(color => `
                            <div class="color-option ${color === 'cyan' ? 'selected' : ''}" 
                                 data-color="${color}" 
                                 style="background-color: ${this.getColorValue(color)}"
                                 onclick="app.selectColor('${color}')"></div>
                        `).join('')}
                    </div>
                </div>
                <button type="submit" class="glass-button" style="width: 100%; margin-top: 16px;">
                    Создать словарь
                </button>
            </form>
        `;
    },

    async handleAddDictionary() {
        const name = document.getElementById('dict-name').value;
        const description = document.getElementById('dict-description').value;
        const color = document.querySelector('.color-option.selected').dataset.color;

        await db.createDictionary(name, description, color);
        await this.loadData();
        this.renderDictionaries();
        this.closeModal();
    },

    selectColor(color) {
        document.querySelectorAll('.color-option').forEach(el => el.classList.remove('selected'));
        document.querySelector(`.color-option[data-color="${color}"]`).classList.add('selected');
    },

    showModal(title, content) {
        const modalHTML = `
            <div class="modal-overlay" onclick="if(event.target === this) app.closeModal()">
                <div class="modal">
                    <div class="modal-header">
                        <h2>${title}</h2>
                        <button class="close-button" onclick="app.closeModal()">&times;</button>
                    </div>
                    ${content}
                </div>
            </div>
        `;
        document.getElementById('modal-container').innerHTML = modalHTML;
    },

    closeModal() {
        document.getElementById('modal-container').innerHTML = '';
    },

    // Actions
    async toggleFavorite(wordId) {
        await db.toggleFavorite(wordId);
        await this.loadData();
        
        // Re-render current view
        if (this.currentTab === 'search') {
            this.renderSearch();
        } else if (this.currentTab === 'favorites') {
            this.renderFavorites();
        }
    },

    async toggleDictionaryActive(dictId) {
        const dict = await db.get('dictionaries', dictId);
        await db.updateDictionary(dictId, { isActive: !dict.isActive });
        await this.loadData();
        this.renderDictionaries();
    },

    async showWordDetail(wordId) {
        const word = await db.get('words', wordId);
        const examples = await db.getExamplesByWord(wordId);
        
        const examplesHTML = examples.length > 0 
            ? examples.map(ex => `
                <div class="glass-card" style="margin-bottom: 12px;">
                    <div style="font-size: 18px; margin-bottom: 8px;" class="chinese">${ex.chineseSentence}</div>
                    <div style="font-size: 14px; color: rgba(0,204,255,0.8); margin-bottom: 8px;">${ex.pinyinSentence}</div>
                    <div style="font-size: 16px; color: rgba(255,255,255,0.85);">${ex.russianTranslation}</div>
                </div>
            `).join('')
            : '<div style="text-align: center; padding: 32px; color: rgba(255,255,255,0.5);">Нет примеров</div>';

        this.showModal('Детали слова', `
            <div class="glass-card" style="margin-bottom: 24px;">
                <div style="font-size: 42px; font-weight: 700; margin-bottom: 12px;" class="chinese">${word.chinese}</div>
                <div style="font-size: 18px; color: rgba(0,204,255,0.9); margin-bottom: 16px;">${word.pinyin}</div>
                <div style="border-top: 1px solid rgba(255,255,255,0.2); margin: 16px 0;"></div>
                <div style="font-size: 22px; color: rgba(255,255,255,0.95);">${word.russian}</div>
                ${word.hskLevel > 0 ? `<div class="hsk-badge" style="margin-top: 16px;">HSK ${word.hskLevel}</div>` : ''}
            </div>
            <h3 style="margin-bottom: 12px;">Примеры использования</h3>
            ${examplesHTML}
        `);
    },

    async showDictionaryDetail(dictId) {
        const dict = await db.get('dictionaries', dictId);
        const words = await db.getWordsByDictionary(dictId);
        
        const wordsHTML = words.length > 0
            ? words.map(word => this.createWordCard(word)).join('')
            : '<div style="text-align: center; padding: 32px; color: rgba(255,255,255,0.5);">Нет слов</div>';

        this.showModal(dict.name, `
            <div class="glass-card" style="margin-bottom: 24px;">
                <div style="display: flex; align-items: center; gap: 16px;">
                    <div class="dict-icon" style="width: 60px; height: 60px; background-color: ${this.getColorValue(dict.color)};">📚</div>
                    <div>
                        <h2 style="margin-bottom: 4px;">${dict.name}</h2>
                        ${dict.description ? `<p style="color: rgba(255,255,255,0.7);">${dict.description}</p>` : ''}
                    </div>
                </div>
            </div>
            ${wordsHTML}
        `);
    },

    async createSampleData() {
        await db.createSampleData();
        await this.loadData();
        this.renderSearch();
        this.renderDictionaries();
    },

    getColorValue(colorName) {
        const colors = {
            'cyan': '#00CCFF',
            'blue': '#3b82f6',
            'purple': '#8b5cf6',
            'pink': '#ec4899',
            'green': '#22c55e',
            'orange': '#f97316'
        };
        return colors[colorName] || '#00CCFF';
    }
};
