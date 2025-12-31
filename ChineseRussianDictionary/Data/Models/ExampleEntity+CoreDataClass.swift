import Foundation
import CoreData

@objc(ExampleEntity)
public class ExampleEntity: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExampleEntity> {
        return NSFetchRequest<ExampleEntity>(entityName: "ExampleEntity")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var chineseSentence: String
    @NSManaged public var pinyinSentence: String
    @NSManaged public var russianTranslation: String
    @NSManaged public var createdAt: Date
    @NSManaged public var word: WordEntity?
}

extension ExampleEntity: Identifiable {}
