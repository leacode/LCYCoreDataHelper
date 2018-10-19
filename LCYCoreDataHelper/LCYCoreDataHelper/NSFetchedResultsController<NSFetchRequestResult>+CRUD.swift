//
//  NSFetchedResultsController<NSFetchRequestResult>+CRUD.swift
//  LCYCoreDataHelper
//
//  Created by leacode on 2018/9/1.
//  Copyright © 2018 leacode. All rights reserved.
//

import Foundation
import CoreData

extension NSFetchedResultsController {
    
    @objc public func delete(object: NSManagedObject) {
        self.managedObjectContext.delete(object)
    }
    
}
