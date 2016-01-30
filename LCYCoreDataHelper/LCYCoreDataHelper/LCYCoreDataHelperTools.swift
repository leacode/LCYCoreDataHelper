
//
//  LCYCoreDataHelperTools.swift
//  LCYCoreDataHelper
//
//  Created by LiChunyu on 16/1/22.
//  Copyright © 2016年 leacode. All rights reserved.
//

import UIKit
import CoreData

extension LCYCoreDataHelper {

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
        
        try saveContext()
        
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
    
}
