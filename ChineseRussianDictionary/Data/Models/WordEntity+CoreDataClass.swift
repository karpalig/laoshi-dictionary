import Foundation
import CoreData

@objc(WordEntity)
public class WordEntity: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WordEntity> {
        return NSFetchRequest<WordEntity>(entityName: "WordEntity")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var chinese: String
    @NSManaged public var pinyin: String
    @NSManaged public var russian: String
    @NSManaged public var isFavorite: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var lastAccessed: Date?
    @NSManaged public var hskLevel: Int16
    @NSManaged public var dictionary: DictionaryEntity?
    @NSManaged public var examples: NSSet?
    
    public var examplesArray: [ExampleEntity] {
        let set = examples as? Set<ExampleEntity> ?? []
        return set.sorted { $0.createdAt < $1.createdAt }
    }
    
    public var hskLevelString: String {
        hskLevel > 0 ? "HSK \(hskLevel)" : ""
    }
}

extension WordEntity {
    @objc(addExamplesObject:)
    @NSManaged public func addToExamples(_ value: ExampleEntity)
    
    @objc(removeExamplesObject:)
    @NSManaged public func removeFromExamples(_ value: ExampleEntity)
    
    @objc(addExamples:)
    @NSManaged public func addToExamples(_ values: NSSet)
    
    @objc(removeExamples:)
    @NSManaged public func removeFromExamples(_ values: NSSet)
}

extension WordEntity: Identifiable {}
