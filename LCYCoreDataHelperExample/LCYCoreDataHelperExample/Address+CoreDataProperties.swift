//
//  Address+CoreDataProperties.swift
//  LCYCoreDataHelperExample
//
//  Created by LiChunyu on 16/1/28.
//  Copyright © 2016年 leacode. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Address {

    @NSManaged var id: NSNumber?
    @NSManaged var parent_id: NSNumber?
    @NSManaged var name: String?
    @NSManaged var pinyin: String?
    @NSManaged var level: NSNumber?

}
