
//
//  LCYSoureceStoreHelper.swift
//  LCYCoreDataHelper
//
//  Created by LiChunyu on 16/1/28.
//  Copyright © 2016年 leacode. All rights reserved.
//

import UIKit
import CoreData

public class LCYSoureceStoreHelper: NSObject {
    
    
    private var sourceStoreFilename: String?
    private var sourceCoordinator: NSPersistentStoreCoordinator?
    private var model: NSManagedObjectModel?
    
    public private(set) var sourceContext: NSManagedObjectContext = {
        return NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
    }()
    
    lazy private var sourceStoreURL: NSURL? = {
        guard let fileName = self.sourceStoreFilename else {
            return nil
        }
        
        guard let path = NSBundle.mainBundle().pathForResource((fileName as NSString).stringByDeletingPathExtension, ofType: (fileName as NSString).pathExtension) else {
            return nil
        }
        
        return NSURL(fileURLWithPath: path)
    }()
    
    // MARK: - Initial
    
    public convenience init(sourceStoreFileName: String) throws {
        self.init()
        
        self.sourceStoreFilename = sourceStoreFileName
        sourceCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model!)
        sourceContext.performBlockAndWait { () -> Void in
            self.sourceContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            self.sourceContext.undoManager = nil
        }
        
    }
    
    public required override init() {
        model = NSManagedObjectModel.mergedModelFromBundles(nil)
        sourceCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model!)
        sourceContext.persistentStoreCoordinator = sourceCoordinator
    }

}
