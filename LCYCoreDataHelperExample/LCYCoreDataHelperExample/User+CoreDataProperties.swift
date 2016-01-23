//
//  User+CoreDataProperties.swift
//  LCYCoreDataHelperExample
//
//  Created by LiChunyu on 16/1/22.
//  Copyright © 2016年 leacode. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension User {

    @NSManaged var id: Int
    @NSManaged var username: String
    @NSManaged var birthday: NSDate
    @NSManaged var cellphone: String
    @NSManaged var age: Int
    @NSManaged var sex: Int
    @NSManaged var isLogin: Bool
    @NSManaged var amount: Double

}
