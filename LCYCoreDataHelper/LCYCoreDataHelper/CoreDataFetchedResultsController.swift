//
//  CoreDataComponent.swift
//  LCYCoreDataHelper
//
//  Created by leacode on 2018/9/2.
//  Copyright © 2018 leacode. All rights reserved.
//

import Foundation
import CoreData

protocol CoreDataFetchedResultsController {
    
    var frc:NSFetchedResultsController<NSFetchRequestResult>! {get set}
    var entity: String! {get set}
    var cacheName: String? {get set}

    func reloadData()
    
}

extension CoreDataFetchedResultsController {
    
    public func performFetch() {
        frc.managedObjectContext.performAndWait { () -> Void in
            do {
                try self.frc.performFetch()
            } catch {
                print("Failed to perform fetch")
            }
            self.reloadData()
        }
    }
    
    public func deleteObject(object: NSManagedObject) {
        
        frc.delete(object: object)
        // TODO: background save
        
        
    }
    
    
    
}
