//
//  Link+CoreDataProperties.swift
//  BookMarksApp
//
//  Created by sunil on 23/03/22.
//

import Foundation
import CoreData


extension Link {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Link> {
        return NSFetchRequest<Link>(entityName: "Link")
    }

    @NSManaged public var uuid: String?
    @NSManaged public var title: NSObject?
    @NSManaged public var urlDescription: NSObject?
    @NSManaged public var url: NSObject?
    @NSManaged public var iconUrl: NSObject?

}
