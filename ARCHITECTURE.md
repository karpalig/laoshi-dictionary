# Архитектура приложения

## 🏛️ Общая архитектура

Приложение построено на **MVVM (Model-View-ViewModel)** архитектуре с использованием SwiftUI и Core Data.

```
┌─────────────────────────────────────────┐
│            SwiftUI Views                │
│  (SearchView, DictionariesView, etc.)   │
└─────────────┬───────────────────────────┘
              │
              │ @ObservedObject
              ▼
┌─────────────────────────────────────────┐
│         DictionaryViewModel             │
│      (Business Logic Layer)             │
└─────────────┬───────────────────────────┘
              │
              │ CRUD operations
              ▼
┌─────────────────────────────────────────┐
│         DataController                  │
│     (Core Data Coordinator)             │
└─────────────┬───────────────────────────┘
              │
              │ NSPersistentContainer
              ▼
┌─────────────────────────────────────────┐
│           Core Data                     │
│  (DictionaryEntity, WordEntity, etc.)   │
└─────────────────────────────────────────┘
```

## 📦 Слои приложения

### 1. Presentation Layer (Views)

**Ответственность:** Отображение UI и обработка пользовательского ввода

**Компоненты:**
- `ContentView.swift` - корневой view с TabView
- `SearchView.swift` - поиск по словам
- `DictionariesView.swift` - управление словарями
- `FavoritesView.swift` - избранные слова
- `WordDetailView.swift` - детальная информация о слове
- `DictionaryDetailView.swift` - содержимое словаря

**Формы редактирования:**
- `AddDictionaryView.swift` / `EditDictionaryView.swift`
- `AddWordView.swift` / `EditWordView.swift`
- `AddExampleView.swift` / `EditExampleView.swift`

**Переиспользуемые компоненты:**
- `GlassCard.swift` - карточка с glass эффектом
- `GlassButton.swift` - кнопка с glass дизайном
- `GlassTextField.swift` - текстовое поле
- `WordCard.swift` - карточка слова
- `ExampleCard.swift` - карточка примера

### 2. Business Logic Layer (ViewModel)

**Ответственность:** Бизнес-логика, управление состоянием, координация данных

**DictionaryViewModel:**
```swift
class DictionaryViewModel: ObservableObject {
    // Published properties для UI
    @Published var dictionaries: [DictionaryEntity]
    @Published var allWords: [WordEntity]
    @Published var searchResults: [WordEntity]
    @Published var favoriteWords: [WordEntity]
    @Published var searchText: String
    
    // CRUD операции
    func createDictionary(...)
    func updateDictionary(...)
    func deleteDictionary(...)
    
    func createWord(...)
    func updateWord(...)
    func deleteWord(...)
    
    func createExample(...)
    func updateExample(...)
    func deleteExample(...)
    
    // Дополнительная логика
    func performSearch(...)
    func toggleFavorite(...)
}
```

**Особенности:**
- Реактивное управление состоянием через Combine
- Debounce для поиска (300ms)
- Централизованная бизнес-логика
- Разделение ответственности

### 3. Data Layer (Models & Core Data)

**Ответственность:** Персистентность данных, модели данных

#### Core Data Stack

```swift
class DataController: ObservableObject {
    static let shared = DataController()
    let container: NSPersistentContainer
    
    func save()
    func deleteObject(_ object: NSManagedObject)
}
```

#### Модели данных

**DictionaryEntity**
- Хранит информацию о словарях
- Связь 1:N с WordEntity
- Каскадное удаление слов

**WordEntity**
- Хранит слова и переводы
- Связь N:1 с DictionaryEntity
- Связь 1:N с ExampleEntity
- Поддержка избранного и HSK уровней

**ExampleEntity**
- Хранит примеры использования
- Связь N:1 с WordEntity
- Полный контекст с переводом

### 4. Utilities Layer

**PinyinHelper.swift:**
- Валидация пиньинь
- Конвертация номеров тонов (ni3 → nǐ)
- Добавление тональных знаков
- Нормализация для поиска
- Анализ китайских иероглифов

**ChineseKeyboardHelper.swift:**
- Помощники для ввода
- Кастомные text fields
- Подсказки по тонам

## 🔄 Поток данных

### Создание слова

```
User Input (AddWordView)
    ↓
DictionaryViewModel.createWord()
    ↓
DataController.save()
    ↓
Core Data
    ↓
Automatic UI Update (via @Published)
    ↓
View refresh
```

### Поиск

```
User types in search field
    ↓
@Published searchText changes
    ↓
Combine debounce (300ms)
    ↓
DictionaryViewModel.performSearch()
    ↓
Filter allWords array
    ↓
Update @Published searchResults
    ↓
View automatically updates
```

## 🎨 UI/UX Принципы

### Glass Design Implementation

```swift
// Основа всех glass компонентов
RoundedRectangle(cornerRadius: 20)
    .fill(.ultraThinMaterial)  // Apple's material effect
    .overlay(
        RoundedRectangle(cornerRadius: 20)
            .stroke(
                LinearGradient(...),  // Subtle border
                lineWidth: 1
            )
    )
    .shadow(...)  // Depth effect
```

### Цветовая схема
- Основной цвет: Cyan (#00CCFF)
- Фон: Темный градиент (0.05-0.1 opacity)
- Текст: White с различной прозрачностью
- Акценты: Purple (HSK), Yellow (избранное)

### Типографика
- Заголовки: System Bold, 24-48pt
- Текст: System Regular, 16-20pt
- Пиньинь: System, 14-16pt, cyan
- Метаданные: System, 12-14pt, opacity 0.6-0.7

## 🔍 Оптимизации

### Производительность

1. **Lazy Loading**
   ```swift
   LazyVStack {  // Создает views только при необходимости
       ForEach(items) { item in
           ItemView(item: item)
       }
   }
   ```

2. **Efficient Core Data Queries**
   ```swift
   request.sortDescriptors = [...]
   request.predicate = NSPredicate(format: "dictionary.isActive == YES")
   ```

3. **Debounced Search**
   ```swift
   $searchText
       .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
       .sink { [weak self] in self?.performSearch($0) }
   ```

### Память

1. **Weak References**
   ```swift
   .sink { [weak self] in ... }
   ```

2. **Automatic Cleanup**
   ```swift
   private var cancellables = Set<AnyCancellable>()
   ```

3. **Core Data Auto-merge**
   ```swift
   container.viewContext.automaticallyMergesChangesFromParent = true
   ```

## 🧪 Тестируемость

### Unit Testing Points

1. **PinyinHelper**
   - Тоны conversion
   - Validation
   - Normalization

2. **DictionaryViewModel**
   - CRUD operations
   - Search logic
   - State management

3. **Core Data Models**
   - Relationships
   - Cascade deletes
   - Data integrity

## 🚀 Масштабируемость

### Возможности расширения

1. **Import/Export словарей**
   - JSON format
   - CSV format
   - Proprietary format

2. **Синхронизация**
   - iCloud sync
   - Cross-device support

3. **Дополнительные функции**
   - Аудио произношение
   - Система карточек (flashcards)
   - Статистика изучения
   - Игры для запоминания

4. **Локализация**
   - English interface
   - More language pairs

5. **API Integration**
   - Online dictionaries
   - Translation services
   - Chinese stroke order

## 📐 Принципы дизайна

### SOLID Principles

1. **Single Responsibility**
   - Каждый View отвечает за одну функцию
   - ViewModel управляет только бизнес-логикой
   - DataController только для Core Data

2. **Open/Closed**
   - Glass компоненты расширяемы через модификаторы
   - Easy to add new Views

3. **Dependency Inversion**
   - Views зависят от абстракций (@Published)
   - Not от конкретных implementations

### SwiftUI Best Practices

1. **Composition over Inheritance**
   ```swift
   struct WordCard: View {
       let word: WordEntity
       let onTap: () -> Void
       let onFavorite: () -> Void
   }
   ```

2. **Single Source of Truth**
   ```swift
   @ObservedObject var viewModel: DictionaryViewModel
   ```

3. **Declarative UI**
   ```swift
   if viewModel.searchResults.isEmpty {
       EmptyStateView()
   } else {
       ResultsListView()
   }
   ```

## 🔐 Безопасность данных

1. **Core Data Encryption** (optional)
2. **Local-only storage** (no cloud by default)
3. **No external dependencies** (privacy-focused)
4. **User data ownership**

## 📊 Метрики производительности

### Целевые показатели

- Launch time: < 1s
- Search response: < 100ms
- Smooth scrolling: 60fps
- Memory usage: < 50MB
- App size: < 10MB

### Мониторинг

- Xcode Instruments
- Memory Graph Debugger
- Network Link Conditioner (для будущей sync)

---

**Архитектура спроектирована для:**
- ✅ Поддерживаемости
- ✅ Тестируемости
- ✅ Масштабируемости
- ✅ Производительности
- ✅ Отличного UX
