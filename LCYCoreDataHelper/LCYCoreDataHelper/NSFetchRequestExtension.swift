//
//  NSFetchRequesExtension.swift
//  LCYCoreDataHelper
//
//  Created by LiChunyu on 16/1/25.
//  Copyright © 2016年 leacode. All rights reserved.
//

import UIKit
import CoreData

extension NSFetchRequest {
    
//    public class func fetchRequestInContext(_ entityName: String, context: NSManagedObjectContext) -> NSFetchRequest {
//        let request = NSFetchRequest()
//        request.entity = NSEntityDescription.entity(forEntityName: entityName, in: context)
//        return request
//    }
    
    @objc
    public func sort(_ key: String, ascending: Bool) {
        let sortDescriptor = NSSortDescriptor(key: key, ascending: ascending)
        guard let _ = self.sortDescriptors else {
            self.sortDescriptors = [sortDescriptor]
            return
        }
        self.sortDescriptors?.append(sortDescriptor)
    }
    
    @objc
    public func sortByAttributes(_ attributes: [String], ascending: Bool) {
        var sortDescriptors: [NSSortDescriptor] = []
        for attributeName in attributes {
            let sortDescriptor = NSSortDescriptor(key: attributeName, ascending: ascending)
            sortDescriptors.append(sortDescriptor)
        }
        self.sortDescriptors = sortDescriptors
    }
    
//    public func fetchFirstObject(_ context: NSManagedObjectContext) -> AnyObject? {
//        self.fetchLimit = 1
//        do {
//            let fetchedObject: AnyObject? = try context.fetch(self).first
//            return fetchedObject
//        } catch {
//            return nil
//        }
//    }
    
 
}
