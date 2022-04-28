//
//  Database.swift
//  BookMarksApp
//
//  Created by sunil on 20/03/22.
//

import Foundation
import CoreData
import UIKit
import SwiftSoup
/// CoreData handling class

protocol DatabaseDelegate: class {
    func didFinishSavingAllCompetitions()
}

class DataBase {
    
    weak var delegate: DatabaseDelegate?
    
    static let sharedInstance = DataBase()
    
    private init() {
        NotionHelper.sharedInstance.delegate = self
//        NotionHelper.sharedInstance.getNotionPages()
    }
    
    // MARK: - Core Data stack
    lazy var applicationDocumentsDirectory: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: "Bookmark", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("Database.sqlite")
        print("DBURL \(url)")
        var failureReason = "There was an error creating or loading the application's saved data."
        
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: [NSMigratePersistentStoresAutomaticallyOption: true,NSInferMappingModelAutomaticallyOption: true])
        } catch {
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            dict[NSUnderlyingErrorKey] = error as NSError
            
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    func tagsFetchResultsController() -> NSFetchedResultsController<NSFetchRequestResult>? {
        let nameSort = NSSortDescriptor(key: "name", ascending: true)
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Tag")
        fetchRequest.fetchBatchSize = 10
        fetchRequest.sortDescriptors = [nameSort]
        
        let moc = managedObjectContext
        
        let fRC = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fRC.performFetch()
            return fRC
        } catch {
            return nil
        }
    }
    
    //MARK: METHODS
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    func insertTagWith(name: String, uuid: String = String()) -> Tag? {
        guard let tag = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: managedObjectContext) as? Tag else {
            print("tag insert error")
            return nil
        }
        tag.name = name
        tag.uuid = uuid
        saveContext()
        return tag
    }
    
    func addLinkForTag(bookmark: Bookmark, tag: Tag) -> Tag {
        guard let link = NSEntityDescription.insertNewObject(forEntityName: "Link", into: managedObjectContext) as? Link else {
            return tag
        }
        
        link.title = bookmark.title
        link.urlDescription = bookmark.description
        link.url = bookmark.website
        link.iconUrl = bookmark.iconUrl
        
        do {
            let html = try String(contentsOf: URL.init(string: bookmark.website)! )
            //print(html)
            let doc: Document = try SwiftSoup.parse(html)
            link.title = try doc.title()
            link.urlDescription = try doc.body()?.text()
            let links = try doc.select("link")
            let iconlinks = try links.filter ({ link in
                let attribute1 = try link.attr("rel")//)
                return (attribute1 == "shortcut icon") || (attribute1 == "icon")
            })
            
            if let icon = iconlinks.first {
                let imageUrl = try icon.attr("href")
                if let _ = URL.init(string: imageUrl) {
                    link.iconUrl = imageUrl
                }
            }
        } catch (let error ) {
            print("error swift soup")
        }
        
        tag.addToRelationship(link)
        
        saveContext()
        
        return tag
    }
    
    func fetchTag(_ tag: Tag) -> Tag? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Tag")
        
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if let name = tag.name {
            let predicate = NSPredicate(format: "name CONTAINS[c] %@", name)
            fetchRequest.predicate = predicate
        }
        
        do {
            let records = try managedObjectContext.fetch(fetchRequest) as! [NSManagedObject]

            for record in records {
                print(record.value(forKey: "name") ?? "no name")
            }
            
            if let tag = records.first as? Tag {
                return tag
            } else {
                return nil
            }

        } catch {
            print(error)
        }
        return nil
    }
    
    func deleteTag(_ tag: Tag) {
        managedObjectContext.delete(tag)
        saveContext()
    }
    
    func deleteAll() {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Tag")
        fetchRequest.returnsObjectsAsFaults = false
        
        do
        {
            let results = try managedObjectContext.fetch(fetchRequest)
            for managedObject in results
            {
                let managedObjectData:NSManagedObject = managedObject as! NSManagedObject
                managedObjectContext.delete(managedObjectData)
            }
        } catch let error as NSError {
            print("Detele all data in Tag error : \(error) \(error.userInfo)")
        }
    }
}

extension DataBase: Notionable {
    func didUpdatedNewLink(tag: Tag, links: [NotionLink]) {
        if let relationship = tag.relationship {
            tag.removeFromRelationship(relationship)
        }
        
        for link in links {
            let bookmark  = Bookmark.init(title: "", description: "", tag: "", website: link.url, iconUrl: "", uuid: link.uuid)
            addLinkForTag(bookmark: bookmark, tag: tag)
        }
    }
    
    func didReceived(pages: [NotionPage]) {
        deleteAll()
        
        for page in pages {
            if let tag = insertTagWith(name: page.title, uuid: page.uuid), let links = page.links {
                for link in links {
                    let bookmark  = Bookmark.init(title: "", description: "", tag: "", website: link.url, iconUrl: "", uuid: link.uuid)
                    addLinkForTag(bookmark: bookmark, tag: tag)
                }
            }
        }
        
    }
}




