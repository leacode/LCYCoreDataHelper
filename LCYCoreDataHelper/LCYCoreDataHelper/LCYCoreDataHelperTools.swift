
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

    func fetchAllCoreDataModels( entityName: String, sortKey: String, ascending: Bool, ctx: NSManagedObjectContext ) -> [AnyObject] {
        
        let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: entityName)
        let sortDescriptor = NSSortDescriptor(key: sortKey, ascending: ascending)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let entity = NSEntityDescription.entityForName("User", inManagedObjectContext: ctx)
        fetchRequest.entity = entity
        
        do {
            let models = try context.executeFetchRequest(fetchRequest)
            return models
        } catch {
            return []
        }
        
    }
    
    /**
     Removes all entities from within the specified `NSManagedObjectContext` excluding a supplied array of entities.
     
     - parameter context: The `NSManagedObjectContext` to remove the Entities from.
     */
    public func deleteAllExistingObjectOfEntity(entityName: String, ctx: NSManagedObjectContext) throws {
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: ctx)
        
        if #available(iOS 9.0, *) {
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try ctx.executeRequest(deleteRequest)
        } else {
            fetchRequest.includesPropertyValues = false
            fetchRequest.includesSubentities = false
            try ctx.executeFetchRequest(fetchRequest).lazy.map { $0 as! NSManagedObject }.forEach(ctx.deleteObject)
        }
        
//        try saveContext()
        try backgroundSaveContext()
        
    }
    
    public func deleteAllMachingPredicate(entityName: String, predicate: NSPredicate, ctx: NSManagedObjectContext) throws {
        
        let request = NSFetchRequest.fetchRequestInContext(entityName, context: ctx)
        request.predicate = predicate
        request.returnsObjectsAsFaults = true
        request.includesPropertyValues = false
        
        if #available(iOS 9.0, *) {
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            try ctx.executeRequest(deleteRequest)
        } else {
            request.includesSubentities = false
            try ctx.executeFetchRequest(request).lazy.map{ $0 as! NSManagedObject }.forEach(ctx.deleteObject)
        }
        
        try saveContext()
        
    }
    
    // MARK: - CORE DATA RESET
    
    func resetContext(moc: NSManagedObjectContext) {
        moc.performBlockAndWait { () -> Void in
            moc.reset()
        }
    }
    
    func reloadStore() -> Bool {
        do {
            try coordinator?.removePersistentStore(self.store!)
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
    
    
    func removeAllStoresFromCoordinator(psc: NSPersistentStoreCoordinator) {
        for s in psc.persistentStores {
            do {
                try psc.removePersistentStore(s)
            } catch {
                print("Error removing persistent store: \(error)")
            }
        }
    }
    
    func resetCoreData() {
        importContext.performBlockAndWait { () -> Void in
            try! self.importContext.save()
            self.resetContext(self.importContext)
        }
        context.performBlockAndWait { () -> Void in
            try! self.context.save()
            self.resetContext(self.context)
        }
        parentContext.performBlockAndWait { () -> Void in
            try! self.parentContext.save()
            self.resetContext(self.parentContext)
        }
        if let coor = coordinator {
            removeAllStoresFromCoordinator(coor)
        }
        store = nil
        iCloudStore = nil
        
    }

    func unloadStore(ps: NSPersistentStore?) -> Bool {
        
        guard let store = ps else {
            return true // No need to reset, store is nil
        }
        guard let psc = store.persistentStoreCoordinator else {
            return true
        }
        do {
            try psc.removePersistentStore(store)
            return false
        } catch {
            return true // Reset complete
        }
        
    }
    
    func removeFileAtURL(url: NSURL) {
        do {
            try NSFileManager.defaultManager().removeItemAtURL(url)
        } catch {
            print("Failed to delete \(error)")
        }
    }
    
    
    
}
