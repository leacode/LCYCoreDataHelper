//
//  NSManagedObjectContextExtension.swift
//  LCYCoreDataHelper
//
//  Created by LiChunyu on 16/1/22.
//  Copyright © 2016年 leacode. All rights reserved.
//

import UIKit
import CoreData

extension NSManagedObjectContext {

    /**
     save context
     
     - throws: save exception
     */
    private func saveContext() throws {
        if hasChanges {
            try save()
            print("context SAVED changes to persistent store")
        } else {
            return
        }
    }
    
    /**
     synchronously save context on the context's queue.
     
     - throws: exception
     */
    public func saveContextAndWait() throws {
        switch concurrencyType {
        case .ConfinementConcurrencyType:
            try saveContext()
        case .MainQueueConcurrencyType,
        .PrivateQueueConcurrencyType:
            try performAndWaitOrThrow(saveContext)
        }
    }

    /**
     synchronously performs the block on the context's queue.
     
     - parameter body: block to perform
     
     - throws: block throw the exception
     
     - returns: the block
     */
    public func performAndWaitOrThrow<Return>(body: () throws -> Return) throws -> Return {
        var result: Return!
        var thrown: ErrorType?
        
        performBlockAndWait {
            do {
                result = try body()
            } catch {
                thrown = error
            }
        }
        
        if let thrown = thrown {
            throw thrown
        } else {
            return result
        }
    }
    
    
}
