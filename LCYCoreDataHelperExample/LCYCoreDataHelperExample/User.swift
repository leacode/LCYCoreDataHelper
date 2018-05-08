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
    
    static var i = 0
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
    }

    class func insertCoreDataModel() {
        
        let user: User? = NSEntityDescription.insertNewObject(forEntityName: "User", into: globalContext!) as? User

        user?.id = i
        i += 1
        user?.username = "User\(i)"
        user?.amount = 23.23

        do {
            try coreDataHelper?.backgroundSaveContext()
        } catch {
            print("save User failed, error: \(error)")
        }
        
    }
    
    class func fetchCoreDataModels() -> [User] {
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "User")
        let entity = NSEntityDescription.entity(forEntityName: "User", in: globalContext!)
        fetchRequest.entity = entity
        
        do {
            let users: [User] = try globalContext?.fetch(fetchRequest) as! [User]
            return users
        } catch {
            return []
        }
        
    }
    
}

