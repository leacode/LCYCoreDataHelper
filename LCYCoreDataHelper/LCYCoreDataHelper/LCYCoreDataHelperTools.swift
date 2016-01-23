
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

    
    
}
