//
//  Tag+CoreDataProperties.swift
//  BookMarksApp
//
//  Created by sunil on 23/03/22.
//

import Foundation
import CoreData


extension Tag {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Tag> {
        return NSFetchRequest<Tag>(entityName: "Tag")
    }

    @NSManaged public var name: String?
    @NSManaged public var uuid: String?
    @NSManaged public var relationship: NSSet?

}

// MARK: Generated accessors for relationship
extension Tag {

    @objc(addRelationshipObject:)
    @NSManaged public func addToRelationship(_ value: Link)

    @objc(removeRelationshipObject:)
    @NSManaged public func removeFromRelationship(_ value: Link)

    @objc(addRelationship:)
    @NSManaged public func addToRelationship(_ values: NSSet)

    @objc(removeRelationship:)
    @NSManaged public func removeFromRelationship(_ values: NSSet)

}
