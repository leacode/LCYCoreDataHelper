//
//  NSManagedObjectContext+AsynchronousDataTransaction.swift
//  taojinziseller
//
//  Created by LiChunyu on 15/6/30.
//  Copyright (c) 2015年 hzwanqing. All rights reserved.
//

import Foundation
import CoreData



extension NSManagedObjectContext {
    
    func saveSynchronously() throws {
    
        self.performAndWait { [unowned self] () -> Void in
            if !self.hasChanges {
                return
            }
           
            do {
                try self.save()
            } catch {
            
            }
            
        }
    
    }

}
