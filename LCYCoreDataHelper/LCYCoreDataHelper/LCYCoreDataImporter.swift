
//
//  LCYCoreDataImporter.swift
//  LCYCoreDataHelper
//
//  Created by LiChunyu on 16/1/28.
//  Copyright © 2016年 leacode. All rights reserved.
//

import UIKit
import CoreData

class LCYCoreDataImporter: NSObject {
    
    class func saveContext(_ context: NSManagedObjectContext) throws {
        
        try context.performAndWaitOrThrow {
            if context.hasChanges {
                try context.save()
            }
        }
        
    }
    
    var entitiesWithUniqueAttributes: [String: String]!
    
    override init() {
        super.init()
    }
    
    convenience init(uniqueAttributes: [String: String]) {
        self.init()
        entitiesWithUniqueAttributes = uniqueAttributes
    }
    
    func arrayForEntity(_ entity: String, inContext context: NSManagedObjectContext, predicate: NSPredicate?) throws -> [AnyObject] {
        
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entity)
        request.fetchBatchSize = 50
        request.predicate = predicate
        
        return try context.fetch(request)
        
    }
    
    func copyUniqueObject(_ object: NSManagedObject, toContext targetContext: NSManagedObjectContext) throws -> NSManagedObject? {
        
        let entity = object.entity.name
        let uniqueAttribute = uniqueAttritureForEntity(entity!)
        let uniqueAttributeValue = object.value(forKey: uniqueAttribute) as! String
        
        if uniqueAttributeValue.count > 0 {
            
            var attributeValuesToCopy: [String: AnyObject] = [String: AnyObject]()
            for attribute in object.entity.attributesByName {
                attributeValuesToCopy[attribute.0] = object.value(forKey: attribute.0) as AnyObject?
            }

            let copiedObject = try insertUniqueObject(entity!, uniqueAttributeValue: uniqueAttributeValue, attributeValues: attributeValuesToCopy, context: targetContext)
            return copiedObject
            
        }
        return nil
        
    }
    
    func existingObjectInContext(_ context: NSManagedObjectContext, entity: String, uniqueAttributeValue: String) throws  -> NSManagedObject?{
        
        let uniqueAttribute = uniqueAttritureForEntity(entity)
        let predicate = NSPredicate(format: "%K==%@", uniqueAttribute, uniqueAttributeValue)
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entity)
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        let fetchRequestResults = try context.fetch(fetchRequest)
        if fetchRequestResults.count == 0 {
            return nil
        }
        return fetchRequestResults.last as? NSManagedObject
    }
    
    func insertUniqueObject(_ entity: String, uniqueAttributeValue: String, attributeValues: [String: AnyObject], context: NSManagedObjectContext) throws -> NSManagedObject?{
        
        let uniqueAttribute = uniqueAttritureForEntity(entity)
        if uniqueAttributeValue.count > 0 {
            guard let existingObject = try existingObjectInContext(context, entity: entity, uniqueAttributeValue: uniqueAttributeValue) else {
                let newObject = NSEntityDescription.insertNewObject(forEntityName: entity, into: context)
                newObject.setValuesForKeys(attributeValues)
                print("Created \(entity) object with \(uniqueAttribute) \(uniqueAttributeValue)")
                return newObject
            }
            return existingObject
        }
        return nil
    }
    
    
    func uniqueAttritureForEntity(_ entity: String) -> String {
        return entitiesWithUniqueAttributes[entity]!
    }
    
    func establishToOneRelationship(_ relationshipName: String, fromObject object: NSManagedObject, toObject relatedObject: NSManagedObject) throws {
        
        guard let _ = object.value(forKey: relationshipName) else {
            return
        }
        
        let relationships = object.entity.relationshipsByName
        let relationship = relationships[relationshipName]
        if !relatedObject.entity.isEqual(relationship?.destinationEntity) {
            return
        }
        
        object.setValue(relatedObject, forKey: relationshipName)
        
        try LCYCoreDataImporter.saveContext(relatedObject.managedObjectContext!)
        try LCYCoreDataImporter.saveContext(object.managedObjectContext!)
        object.managedObjectContext?.refresh(object, mergeChanges: false)
        relatedObject.managedObjectContext?.refresh(relatedObject, mergeChanges: false)
        
    }
    
    func establishToManyRelationship(_ relationShipName: String, fromObject object: NSManagedObject, withSourceSet sourceSet: NSMutableSet) throws {
        
        let copiedSet = object.mutableSetValue(forKey: relationShipName)
        
        for relatedObject in sourceSet {
            if let copiedRelatedObject = try copyUniqueObject(relatedObject as! NSManagedObject, toContext: object.managedObjectContext!) {
                copiedSet.add(copiedRelatedObject)
            }
        }
        
        try LCYCoreDataImporter.saveContext(object.managedObjectContext!)
        object.managedObjectContext?.refresh(object, mergeChanges: false)
    }
    
    func establishOrderedToManyRelationship(_ relationshipName: String, fromObject object: NSManagedObject, withSourceSet sourceSet: NSMutableOrderedSet) throws {
        
        let copiedSet = object.mutableOrderedSetValue(forKey: relationshipName)
        for relatedObject in sourceSet {
            if let copiedRelatedObject = try copyUniqueObject(relatedObject as! NSManagedObject, toContext: object.managedObjectContext!) {
                copiedSet.add(copiedRelatedObject)
            }
            
        }
        
        try LCYCoreDataImporter.saveContext(object.managedObjectContext!)
        object.managedObjectContext?.refresh(object, mergeChanges: false)
    }
    
    func copyRelationshipsFromObject(_ sourceObject: NSManagedObject, toContext targetContext: NSManagedObjectContext) throws {
        
        guard let copiedObject = try copyUniqueObject(sourceObject, toContext: targetContext) else {
            return
        }
        let relationships = sourceObject.entity.relationshipsByName
        for relationshipName in relationships {
            
            let relationship: NSRelationshipDescription = relationships[relationshipName.0]!
            if let _ =  sourceObject.value(forKey: relationshipName.0) {
                if relationship.isToMany && relationship.isOrdered {
                    
                    // COPY To-Many Ordered
                    let sourceSet = sourceObject.mutableOrderedSetValue(forKey: relationshipName.0)
                    try establishOrderedToManyRelationship(relationshipName.0, fromObject: copiedObject, withSourceSet: sourceSet)
                    
                } else if relationship.isToMany && !relationship.isOrdered {
                    
                    // COPY To-Many
                    let sourceSet = sourceObject.mutableSetValue(forKey: relationshipName.0)
                    try establishToManyRelationship(relationshipName.0, fromObject: copiedObject, withSourceSet: sourceSet)
                    
                }else {
                    
                    // COPY To-One
                    let relatedSourceObject: NSManagedObject = sourceObject.value(forKey: relationshipName.0) as! NSManagedObject
                    guard let relatiedCopiedObject = try copyUniqueObject(relatedSourceObject, toContext: targetContext) else {
                        return
                    }
                    try establishToOneRelationship(relationshipName.0, fromObject: copiedObject, toObject: relatiedCopiedObject)
                    
                }
            }
            
        }
        
    }
    
    func deepCopyEntities(_ entities: [String], fromContext sourceContext: NSManagedObjectContext, toContext targetContext: NSManagedObjectContext) throws {
        for entity in entities {
            
            let sourceObjects = try arrayForEntity(entity, inContext: sourceContext, predicate: nil)
            
            for sourceObject in sourceObjects {
                _ = try self.copyUniqueObject(sourceObject as! NSManagedObject, toContext: targetContext)
                try self.copyRelationshipsFromObject(sourceObject as! NSManagedObject, toContext: targetContext)
            }
            
        }
    }

}
