
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

    func fetchCoreDataModels(entityName: String, sortKey: String, ascending: Bool ) -> [AnyObject] {
        
        let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: entityName)
        let sortDescriptor = NSSortDescriptor(key: sortKey, ascending: ascending)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let entity = NSEntityDescription.entityForName("User", inManagedObjectContext: self.context)
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
    public func removeAll(entityName: String) throws {
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: context)
        
        if #available(iOS 9.0, *) {
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try context.executeRequest(deleteRequest)
        } else {
            fetchRequest.includesPropertyValues = false
            fetchRequest.includesSubentities = false
            try context.executeFetchRequest(fetchRequest).lazy.map { $0 as! NSManagedObject }.forEach(context.deleteObject)
        }
        
        try saveContext()
        
    }

    
    
}
