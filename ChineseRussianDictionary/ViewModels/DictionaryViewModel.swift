import Foundation
import CoreData
import Combine

class DictionaryViewModel: ObservableObject {
    @Published var dictionaries: [DictionaryEntity] = []
    @Published var allWords: [WordEntity] = []
    @Published var searchResults: [WordEntity] = []
    @Published var favoriteWords: [WordEntity] = []
    @Published var searchText: String = ""
    
    private let dataController = DataController.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        fetchDictionaries()
        fetchAllWords()
        setupSearch()
    }
    
    // MARK: - Dictionary Management
    
    func fetchDictionaries() {
        let request: NSFetchRequest<DictionaryEntity> = DictionaryEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DictionaryEntity.createdAt, ascending: false)]
        
        do {
            dictionaries = try dataController.container.viewContext.fetch(request)
        } catch {
            print("Failed to fetch dictionaries: \(error)")
        }
    }
    
    func createDictionary(name: String, description: String, color: String) {
        let context = dataController.container.viewContext
        let dictionary = DictionaryEntity(context: context)
        dictionary.id = UUID()
        dictionary.name = name
        dictionary.descriptionText = description
        dictionary.color = color
        dictionary.isActive = true
        dictionary.createdAt = Date()
        
        dataController.save()
        fetchDictionaries()
    }
    
    func updateDictionary(_ dictionary: DictionaryEntity, name: String, description: String, color: String) {
        dictionary.name = name
        dictionary.descriptionText = description
        dictionary.color = color
        
        dataController.save()
        fetchDictionaries()
    }
    
    func deleteDictionary(_ dictionary: DictionaryEntity) {
        dataController.deleteObject(dictionary)
        fetchDictionaries()
    }
    
    func toggleDictionaryActive(_ dictionary: DictionaryEntity) {
        dictionary.isActive.toggle()
        dataController.save()
        fetchDictionaries()
    }
    
    // MARK: - Word Management
    
    func fetchAllWords() {
        let request: NSFetchRequest<WordEntity> = WordEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WordEntity.createdAt, ascending: false)]
        request.predicate = NSPredicate(format: "dictionary.isActive == YES")
        
        do {
            allWords = try dataController.container.viewContext.fetch(request)
            fetchFavorites()
        } catch {
            print("Failed to fetch words: \(error)")
        }
    }
    
    func fetchWords(for dictionary: DictionaryEntity) -> [WordEntity] {
        return dictionary.wordsArray
    }
    
    func createWord(chinese: String, pinyin: String, russian: String, hskLevel: Int16, dictionary: DictionaryEntity) {
        let context = dataController.container.viewContext
        let word = WordEntity(context: context)
        word.id = UUID()
        word.chinese = chinese
        word.pinyin = pinyin
        word.russian = russian
        word.hskLevel = hskLevel
        word.isFavorite = false
        word.createdAt = Date()
        word.dictionary = dictionary
        
        dataController.save()
        fetchAllWords()
    }
    
    func updateWord(_ word: WordEntity, chinese: String, pinyin: String, russian: String, hskLevel: Int16) {
        word.chinese = chinese
        word.pinyin = pinyin
        word.russian = russian
        word.hskLevel = hskLevel
        
        dataController.save()
        fetchAllWords()
    }
    
    func deleteWord(_ word: WordEntity) {
        dataController.deleteObject(word)
        fetchAllWords()
    }
    
    func toggleFavorite(_ word: WordEntity) {
        word.isFavorite.toggle()
        dataController.save()
        fetchAllWords()
    }
    
    func updateLastAccessed(_ word: WordEntity) {
        word.lastAccessed = Date()
        dataController.save()
    }
    
    // MARK: - Example Management
    
    func createExample(for word: WordEntity, chinese: String, pinyin: String, russian: String) {
        let context = dataController.container.viewContext
        let example = ExampleEntity(context: context)
        example.id = UUID()
        example.chineseSentence = chinese
        example.pinyinSentence = pinyin
        example.russianTranslation = russian
        example.createdAt = Date()
        example.word = word
        
        dataController.save()
        fetchAllWords()
    }
    
    func updateExample(_ example: ExampleEntity, chinese: String, pinyin: String, russian: String) {
        example.chineseSentence = chinese
        example.pinyinSentence = pinyin
        example.russianTranslation = russian
        
        dataController.save()
        fetchAllWords()
    }
    
    func deleteExample(_ example: ExampleEntity) {
        dataController.deleteObject(example)
        fetchAllWords()
    }
    
    // MARK: - Search
    
    private func setupSearch() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] searchText in
                self?.performSearch(searchText)
            }
            .store(in: &cancellables)
    }
    
    func performSearch(_ query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        searchResults = allWords.filter { word in
            word.chinese.lowercased().contains(trimmedQuery) ||
            word.pinyin.lowercased().contains(trimmedQuery) ||
            word.russian.lowercased().contains(trimmedQuery)
        }
    }
    
    func fetchFavorites() {
        favoriteWords = allWords.filter { $0.isFavorite }
    }
    
    // MARK: - Sample Data
    
    func createSampleData() {
        // Create default dictionary
        let context = dataController.container.viewContext
        let defaultDict = DictionaryEntity(context: context)
        defaultDict.id = UUID()
        defaultDict.name = "Основной словарь"
        defaultDict.descriptionText = "Основной китайско-русский словарь"
        defaultDict.color = "cyan"
        defaultDict.isActive = true
        defaultDict.createdAt = Date()
        
        // Add sample words
        let sampleWords = [
            ("你好", "nǐ hǎo", "Привет", 1),
            ("谢谢", "xièxie", "Спасибо", 1),
            ("再见", "zàijiàn", "До свидания", 1),
            ("学习", "xuéxí", "Учиться", 2),
            ("汉语", "hànyǔ", "Китайский язык", 3)
        ]
        
        for (chinese, pinyin, russian, hsk) in sampleWords {
            let word = WordEntity(context: context)
            word.id = UUID()
            word.chinese = chinese
            word.pinyin = pinyin
            word.russian = russian
            word.hskLevel = Int16(hsk)
            word.isFavorite = false
            word.createdAt = Date()
            word.dictionary = defaultDict
            
            // Add example
            if chinese == "你好" {
                let example = ExampleEntity(context: context)
                example.id = UUID()
                example.chineseSentence = "你好，我是学生。"
                example.pinyinSentence = "Nǐ hǎo, wǒ shì xuésheng."
                example.russianTranslation = "Привет, я студент."
                example.createdAt = Date()
                example.word = word
            }
        }
        
        dataController.save()
        fetchDictionaries()
        fetchAllWords()
    }
}
