
//
//  LCYSoureceStoreHelper.swift
//  LCYCoreDataHelper
//
//  Created by LiChunyu on 16/1/28.
//  Copyright © 2016年 leacode. All rights reserved.
//

import UIKit
import CoreData

open class LCYSoureceStoreHelper: NSObject {
    
    
    fileprivate var sourceStoreFilename: String?
    fileprivate var sourceCoordinator: NSPersistentStoreCoordinator?
    fileprivate var model: NSManagedObjectModel?
    
    open fileprivate(set) var sourceContext: NSManagedObjectContext = {
        return NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
    }()
    
    lazy fileprivate var sourceStoreURL: URL? = {
        guard let fileName = self.sourceStoreFilename else {
            return nil
        }
        
        guard let path = Bundle.main.path(forResource: (fileName as NSString).deletingPathExtension, ofType: (fileName as NSString).pathExtension) else {
            return nil
        }
        
        return URL(fileURLWithPath: path)
    }()
    
    // MARK: - Initial
    
    public convenience init(sourceStoreFileName: String) throws {
        self.init()
        
        self.sourceStoreFilename = sourceStoreFileName
        sourceCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model!)
        sourceContext.performAndWait { () -> Void in
            self.sourceContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            self.sourceContext.undoManager = nil
        }
        
    }
    
    public required override init() {
        model = NSManagedObjectModel.mergedModel(from: nil)
        sourceCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model!)
        sourceContext.persistentStoreCoordinator = sourceCoordinator
    }

}
