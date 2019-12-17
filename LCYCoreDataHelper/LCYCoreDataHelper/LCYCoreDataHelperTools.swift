
//
//  LCYCoreDataHelperTools.swift
//  LCYCoreDataHelper
//
//  Created by LiChunyu on 16/1/22.
//  Copyright © 2016年 leacode. All rights reserved.
//

import UIKit
import CoreData

public extension LCYCoreDataHelper {

    func fetchAllCoreDataModels( _ entityName: String, sortKey: String, ascending: Bool, ctx: NSManagedObjectContext ) -> [AnyObject] {
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
        let sortDescriptor = NSSortDescriptor(key: sortKey, ascending: ascending)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let entity = NSEntityDescription.entity(forEntityName: "User", in: ctx)
        fetchRequest.entity = entity
        
        do {
            let models = try context.fetch(fetchRequest)
            return models as [AnyObject]
        } catch {
            return []
        }
        
    }
    
    /**
     Removes all entities from within the specified `NSManagedObjectContext` excluding a supplied array of entities.
     
     - parameter context: The `NSManagedObjectContext` to remove the Entities from.
     */
    func deleteAllExistingObjectOfEntity(_ entityName: String, ctx: NSManagedObjectContext) throws {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
        fetchRequest.entity = NSEntityDescription.entity(forEntityName: entityName, in: ctx)
        
        if #available(iOS 9.0, *) {
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try ctx.execute(deleteRequest)
        } else {
            fetchRequest.includesPropertyValues = false
            fetchRequest.includesSubentities = false
            try ctx.fetch(fetchRequest).lazy.map { $0 as! NSManagedObject }.forEach(ctx.delete(_:))
        }
        
//        try saveContext()
        try backgroundSaveContext()
        
    }
    
    func deleteAllMachingPredicate(_ entityName: String, predicate: NSPredicate, ctx: NSManagedObjectContext) throws {
        
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        request.entity = NSEntityDescription.entity(forEntityName: entityName, in: ctx)
        request.predicate = predicate
        request.returnsObjectsAsFaults = true
        request.includesPropertyValues = false
        
        if #available(iOS 9.0, *) {
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            let result = try ctx.execute(deleteRequest) as? NSBatchDeleteResult
            let objectIDArray = result?.result as? [NSManagedObjectID]
            let changes = [NSDeletedObjectsKey : objectIDArray]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes as [AnyHashable : Any], into: [ctx])
        } else {
            request.includesSubentities = false
            try ctx.fetch(request).lazy.map{ $0 as! NSManagedObject }.forEach(ctx.delete(_:))
        }
        
        try saveContext()
    }
    
    func delete(object: NSManagedObject, ctx: NSManagedObjectContext) {
        
        ctx.delete(object)
        do {
            try backgroundSaveContext()
        } catch {
            fatalError("Failure to save context: \(error)")
        }
    }
    
    // MARK: - CORE DATA RESET
    
    func resetContext(_ moc: NSManagedObjectContext) {
        moc.performAndWait { () -> Void in
            moc.reset()
        }
    }
    
    func reloadStore() -> Bool {
        do {
            try coordinator.remove(self.store!)
            resetContext(sourceContext)
            resetContext(importContext)
            resetContext(context)
            resetContext(parentContext)
            store = nil
            try setupCoreData()
            somethingChanged()
            if (store != nil) {
                return true
            }
        } catch {
            return false
        }
        return false
    }
    
    func removeAllStoresFromCoordinator(_ psc: NSPersistentStoreCoordinator) {
        for s in psc.persistentStores {
            do {
                try psc.remove(s)
            } catch {
                print("Error removing persistent store: \(error)")
            }
        }
    }
    
    func resetCoreData() {
        importContext.performAndWait { () -> Void in
            try! self.importContext.save()
            self.resetContext(self.importContext)
        }
        context.performAndWait { () -> Void in
            try! self.context.save()
            self.resetContext(self.context)
        }
        parentContext.performAndWait { () -> Void in
            try! self.parentContext.save()
            self.resetContext(self.parentContext)
        }
        removeAllStoresFromCoordinator(coordinator)
        store = nil
        iCloudStore = nil
        
    }

    func unloadStore(_ ps: NSPersistentStore?) -> Bool {
        
        guard let store = ps else {
            return true // No need to reset, store is nil
        }
        guard let psc = store.persistentStoreCoordinator else {
            return true
        }
        do {
            try psc.remove(store)
            return false
        } catch {
            return true // Reset complete
        }
        
    }
    
    func removeFileAtURL(_ url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("Failed to delete \(error)")
        }
    }
    
}
