//
//  Product+CoreDataProperties.swift
//  LCYCoreDataHelperExample
//
//  Created by LiChunyu on 16/1/24.
//  Copyright © 2016年 leacode. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Product {

    @NSManaged var productId: Int
    @NSManaged var productName: String
    @NSManaged var productPrice: Double
    @NSManaged var creationDate: NSDate
    @NSManaged var productIntroduction: String
    @NSManaged var collection: Bool

}
