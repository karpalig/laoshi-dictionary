import Foundation
import CoreData

@objc(DictionaryEntity)
public class DictionaryEntity: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DictionaryEntity> {
        return NSFetchRequest<DictionaryEntity>(entityName: "DictionaryEntity")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var descriptionText: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var color: String?
    @NSManaged public var words: NSSet?
    
    public var wordsArray: [WordEntity] {
        let set = words as? Set<WordEntity> ?? []
        return set.sorted { $0.createdAt > $1.createdAt }
    }
    
    public var activeWordsCount: Int {
        wordsArray.count
    }
}

extension DictionaryEntity {
    @objc(addWordsObject:)
    @NSManaged public func addToWords(_ value: WordEntity)
    
    @objc(removeWordsObject:)
    @NSManaged public func removeFromWords(_ value: WordEntity)
    
    @objc(addWords:)
    @NSManaged public func addToWords(_ values: NSSet)
    
    @objc(removeWords:)
    @NSManaged public func removeFromWords(_ values: NSSet)
}

extension DictionaryEntity: Identifiable {}
