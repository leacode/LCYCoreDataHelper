//
//  LcyCoreDataHelper+Context.swift
//  LCYCoreDataHelper
//
//  Created by leacode on 2018/9/1.
//  Copyright © 2018 leacode. All rights reserved.
//

import Foundation
import CoreData

extension LCYCoreDataHelper {
    
    public func createFetchedResultsController(fetchRequest: NSFetchRequest<NSFetchRequestResult>, cacheName: String) -> NSFetchedResultsController<NSFetchRequestResult> {
        
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.context, sectionNameKeyPath: nil, cacheName: cacheName)
        
    }
    
}
