
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
    
    class func saveContext(context: NSManagedObjectContext) throws {
        
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
    
    func arrayForEntity(entity: String, inContext context: NSManagedObjectContext, predicate: NSPredicate?) throws -> [AnyObject] {
        
        let request = NSFetchRequest(entityName: entity)
        request.fetchBatchSize = 50
        request.predicate = predicate
        
        return try context.executeFetchRequest(request)
        
    }
    
    func copyUniqueObject(object: NSManagedObject, toContext targetContext: NSManagedObjectContext) throws -> NSManagedObject? {
        
        let entity = object.entity.name
        let uniqueAttribute = uniqueAttritureForEntity(entity!)
        let uniqueAttributeValue = object.valueForKey(uniqueAttribute) as! String
        
        if uniqueAttributeValue.characters.count > 0 {
            
            var attributeValuesToCopy: [String: AnyObject] = [String: AnyObject]()
            for attribute in object.entity.attributesByName {
                attributeValuesToCopy[attribute.0] = object.valueForKey(attribute.0)
            }

            let copiedObject = try insertUniqueObject(entity!, uniqueAttributeValue: uniqueAttributeValue, attributeValues: attributeValuesToCopy, context: targetContext)
            return copiedObject
            
        }
        return nil
        
    }
    
    func existingObjectInContext(context: NSManagedObjectContext, entity: String, uniqueAttributeValue: String) throws  -> NSManagedObject?{
        
        let uniqueAttribute = uniqueAttritureForEntity(entity)
        let predicate = NSPredicate(format: "%K==%@", uniqueAttribute, uniqueAttributeValue)
        let fetchRequest = NSFetchRequest(entityName: entity)
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        let fetchRequestResults = try context.executeFetchRequest(fetchRequest)
        if fetchRequestResults.count == 0 {
            return nil
        }
        return fetchRequestResults.last as? NSManagedObject
    }
    
    func insertUniqueObject(entity: String, uniqueAttributeValue: String, attributeValues: [String: AnyObject], context: NSManagedObjectContext) throws -> NSManagedObject?{
        
        let uniqueAttribute = uniqueAttritureForEntity(entity)
        if uniqueAttributeValue.characters.count > 0 {
            guard let existingObject = try existingObjectInContext(context, entity: entity, uniqueAttributeValue: uniqueAttributeValue) else {
                let newObject = NSEntityDescription.insertNewObjectForEntityForName(entity, inManagedObjectContext: context)
                newObject.setValuesForKeysWithDictionary(attributeValues)
                print("Created \(entity) object with \(uniqueAttribute) \(uniqueAttributeValue)")
                return newObject
            }
            return existingObject
        }
        return nil
    }
    
    
    func uniqueAttritureForEntity(entity: String) -> String {
        return entitiesWithUniqueAttributes[entity]!
    }
    
    func establishToOneRelationship(relationshipName: String, fromObject object: NSManagedObject, toObject relatedObject: NSManagedObject) throws {
        
        guard let _ = object.valueForKey(relationshipName) else {
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
        object.managedObjectContext?.refreshObject(object, mergeChanges: false)
        relatedObject.managedObjectContext?.refreshObject(relatedObject, mergeChanges: false)
        
    }
    
    func establishToManyRelationship(relationShipName: String, fromObject object: NSManagedObject, withSourceSet sourceSet: NSMutableSet) throws {
        
        let copiedSet = object.mutableSetValueForKey(relationShipName)
        
        for relatedObject in sourceSet {
            if let copiedRelatedObject = try copyUniqueObject(relatedObject as! NSManagedObject, toContext: object.managedObjectContext!) {
                copiedSet.addObject(copiedRelatedObject)
            }
        }
        
        try LCYCoreDataImporter.saveContext(object.managedObjectContext!)
        object.managedObjectContext?.refreshObject(object, mergeChanges: false)
    }
    
    func establishOrderedToManyRelationship(relationshipName: String, fromObject object: NSManagedObject, withSourceSet sourceSet: NSMutableOrderedSet) throws {
        
        let copiedSet = object.mutableOrderedSetValueForKey(relationshipName)
        for relatedObject in sourceSet {
            if let copiedRelatedObject = try copyUniqueObject(relatedObject as! NSManagedObject, toContext: object.managedObjectContext!) {
                copiedSet.addObject(copiedRelatedObject)
            }
            
        }
        
        try LCYCoreDataImporter.saveContext(object.managedObjectContext!)
        object.managedObjectContext?.refreshObject(object, mergeChanges: false)
    }
    
    func copyRelationshipsFromObject(sourceObject: NSManagedObject, toContext targetContext: NSManagedObjectContext) throws {
        
        guard let copiedObject = try copyUniqueObject(sourceObject, toContext: targetContext) else {
            return
        }
        let relationships = sourceObject.entity.relationshipsByName
        for relationshipName in relationships {
            
            let relationship: NSRelationshipDescription = relationships[relationshipName.0]!
            if let _ =  sourceObject.valueForKey(relationshipName.0) {
                if relationship.toMany && relationship.ordered {
                    
                    // COPY To-Many Ordered
                    let sourceSet = sourceObject.mutableOrderedSetValueForKey(relationshipName.0)
                    try establishOrderedToManyRelationship(relationshipName.0, fromObject: copiedObject, withSourceSet: sourceSet)
                    
                } else if relationship.toMany && !relationship.ordered {
                    
                    // COPY To-Many
                    let sourceSet = sourceObject.mutableSetValueForKey(relationshipName.0)
                    try establishToManyRelationship(relationshipName.0, fromObject: copiedObject, withSourceSet: sourceSet)
                    
                }else {
                    
                    // COPY To-One
                    let relatedSourceObject: NSManagedObject = sourceObject.valueForKey(relationshipName.0) as! NSManagedObject
                    guard let relatiedCopiedObject = try copyUniqueObject(relatedSourceObject, toContext: targetContext) else {
                        return
                    }
                    try establishToOneRelationship(relationshipName.0, fromObject: copiedObject, toObject: relatiedCopiedObject)
                    
                }
            }
            
        }
        
    }
    
    func deepCopyEntities(entities: [String], fromContext sourceContext: NSManagedObjectContext, toContext targetContext: NSManagedObjectContext) throws {
        for entity in entities {
            
            let sourceObjects = try arrayForEntity(entity, inContext: sourceContext, predicate: nil)
            
            for sourceObject in sourceObjects {
                try self.copyUniqueObject(sourceObject as! NSManagedObject, toContext: targetContext)
                try self.copyRelationshipsFromObject(sourceObject as! NSManagedObject, toContext: targetContext)
            }
            
        }
    }

}
