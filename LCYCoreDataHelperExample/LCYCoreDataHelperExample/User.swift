//
//  User.swift
//  LCYCoreDataHelperExample
//
//  Created by LiChunyu on 16/1/22.
//  Copyright © 2016年 leacode. All rights reserved.
//

import Foundation
import CoreData
import LCYCoreDataHelper

class User: NSManagedObject {
    
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
    }

    class func insertCoreDataModel() {
        
        let user: User? = NSEntityDescription.insertNewObjectForEntityForName("User", inManagedObjectContext: globalContext!) as? User
        
        user?.id = 231312
        user?.username = "旺仔牛奶"
        user?.amount = 23.23

        do {
            try coreDataHelper?.saveContext()
        } catch {
            print("save User failed, error: \(error)")
        }
        
    }
    
    class func fetchCoreDataModels() -> [User] {
        
        let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "User")
        let entity = NSEntityDescription.entityForName("User", inManagedObjectContext: globalContext!)
        fetchRequest.entity = entity
        
        do {
            let users: [User] = try globalContext?.executeFetchRequest(fetchRequest) as! [User]
            return users
        } catch {
            return []
        }
        
    }
    
    
       
    
}












