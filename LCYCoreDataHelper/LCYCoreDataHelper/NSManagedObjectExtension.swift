//
//  NSManagedObjectExtension.swift
//  
//
//  Created by LiChunyu on 16/1/21.
//  Copyright © 2016年 Leacode. All rights reserved.
//

import UIKit
import CoreData

public extension NSManagedObject {

    /**
     Removes all entities from within the specified `NSManagedObjectContext` excluding a supplied array of entities.
     
     - parameter context: The `NSManagedObjectContext` to remove the Entities from.
     */
    public func removeAll(context: NSManagedObjectContext) throws {
        let fetchRequest = NSFetchRequest(entityName: self.entity.name!)
        fetchRequest.entity = NSEntityDescription.entityForName(self.entity.name!, inManagedObjectContext: context)
        try removeAllObjectsReturnedByRequest(fetchRequest, inContext: context)
    }
    
    /**
     remove all objects returned by request
     
     - parameter fetchRequest: fetch request
     - parameter context: The `NSManagedObjectContext` to remove the Entities from.
     
     - throws: delete exception
     */
    public func removeAllObjectsReturnedByRequest(fetchRequest: NSFetchRequest, inContext context: NSManagedObjectContext) throws {
        
        if #available(iOS 9.0, *) {
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try context.executeRequest(deleteRequest)
        } else {
            fetchRequest.includesPropertyValues = false
            fetchRequest.includesSubentities = false
            try context.executeFetchRequest(fetchRequest).lazy.map { $0 as! NSManagedObject }.forEach(context.deleteObject)
        }
        
        
    }
    
    
}
