
//
//  LCYCoreDataHelperICloud.swift
//  LCYCoreDataHelper
//
//  Created by LiChunyu on 16/2/5.
//  Copyright © 2016年 leacode. All rights reserved.
//

import UIKit
import CoreData

extension LCYCoreDataHelper {
    
//    - (NSURL *)iCloudStoreURL {
//    if (debug==1) {
//    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
//    }
//    return [[self applicationStoresDirectory]
//    URLByAppendingPathComponent:iCloudStoreFilename];
//    }
    
    func iCloudStoreURL() -> NSURL? {
        guard let filename = iCloudStoreFilename else {
            return nil
        }
        return self.applicationStoresDirectory.URLByAppendingPathComponent(filename)
    }
    
    func iCloudAccountIsSignedIn() -> Bool {
        
        guard let token = NSFileManager.defaultManager().ubiquityIdentityToken else {
            return false
        }
        print("** iCloud is SIGNED IN with token '\(token)' **")
        return true
        
    }
    
    func loadiCloudStore(needAlert: Bool = false) throws -> Bool {
        if iCloudStore != nil {
            // Don’t load iCloud store if it’s already loaded
            return true
        }
        let options: [NSObject: AnyObject] = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true, NSPersistentStoreUbiquitousContentNameKey: self.storeName]
        do {
            iCloudStore = try coordinator?.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: iCloudStoreURL(), options: options)
            if needAlert {
                self.confirmMergeWithiCloud()
            } else {
                try self.mergeNoniCloudDataWithiCloud()
            }
            return true
        } catch {
            return false
        }
    }
    
    func listenForStoreChanges() {
        let dc = NSNotificationCenter.defaultCenter()
        dc.addObserver(self, selector: Selector("storesWillChange:"), name: NSPersistentStoreCoordinatorStoresWillChangeNotification, object: self.coordinator)
        dc.addObserver(self, selector: Selector("storesDidChange:"), name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: self.coordinator)
        dc.addObserver(self, selector: Selector("persistentStoreDidImportUbiquitiousContentChanges:"), name: NSPersistentStoreDidImportUbiquitousContentChangesNotification, object: self.coordinator)
    }
    
    func storesWillChange(n: NSNotification) {
        do {
            try self.importContext.performAndWaitOrThrow {
                try self.importContext.save()
                self.resetContext(self.importContext)
            }
            try self.context.performOrThrow({
                try self.context.save()
                self.resetContext(self.context)
            })
            try parentContext.performAndWaitOrThrow({
                try self.parentContext.save()
                self.resetContext(self.parentContext)
            })
            
            NSNotificationCenter.defaultCenter().postNotificationName("SomethingChanged", object: nil)
        } catch {
            print("save changes error: \(error)")
        }
    }
    
    func storesDidChange(n: NSNotification) {
         NSNotificationCenter.defaultCenter().postNotificationName("SomethingChanged", object: nil)
    }
    
    func persistentStoreDidImportUbiquitiousContentChanges(n: NSNotification) {
        context.performBlock { () -> Void in
            self.context.mergeChangesFromContextDidSaveNotification(n)
            NSNotificationCenter.defaultCenter().postNotificationName("SomethingChanged", object: nil)
        }
    }
    
    func iCloudEnabledByUser() -> Bool {
        NSUserDefaults.standardUserDefaults().synchronize()
        if let icloudEnabled = NSUserDefaults.standardUserDefaults().objectForKey("iCloudEnabled")?.boolValue {
            if icloudEnabled {
                return true
            }
        }
        return false
    }
    
    // MARK: - ICLOUD SEEDING
    
    func confirmMergeWithiCloud() {
        
        let alertView = UIAlertView(title: "Merge with iCloud?", message: "This will move your existing data into iCloud. If you don't merge now, you can merge later by toggling iCloud for this application in Settings.", delegate: self, cancelButtonTitle: "Don't merge", otherButtonTitles: "Merge")
        
        alertView.tag = 1
        alertView.show()
    
    }

    public func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        
        if alertView.tag == 1 { // merge icloud
            
            if buttonIndex == alertView.firstOtherButtonIndex {
                do {
                    try self.mergeNoniCloudDataWithiCloud()
                } catch {
                    
                }
            }
        
        }
        
    }
    
    func mergeNoniCloudDataWithiCloud() throws {
        
        guard let attributes = selectedUniqueAttributes else {
            return
        }
        
        guard let entities = entitiesToCopy else {
            return
        }
        
        importTimer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: ("somethingChanged"), userInfo: nil, repeats: true)
        
        try seedContext.performOrThrow {
            
            if self.loadNoniCloudStoreAsSeedStore() {
                print("*** STARTED DEEP COPY FROM NON-ICLOUD STORE TO ICLOUD STORE ***")
                
                let importer = LCYCoreDataImporter(uniqueAttributes: attributes)
                try importer.deepCopyEntities(entities, fromContext: self.seedContext, toContext: self.context)
                self.context.performBlock { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName("SomethingChanged", object: nil)
                    print("*** FINISHED DEEP COPY FROM NON-ICLOUD STORE TO ICLOUD STORE ***")
                    print("*** REMOVING OLD NON-ICLOUD STORE ***")
                    if self.unloadStore(self.seedStore) {
                        self.context.performBlock({ () -> Void in
                            // Tell the interface to refresh once import completes
                            NSNotificationCenter.defaultCenter().postNotificationName("SomethingChanged", object: nil)
                            
                            // Remove migrated store
                            let wal = self.storeName.stringByAppendingString("-wal")
                            let shm = self.storeName.stringByAppendingString("-shm")
                            self.removeFileAtURL(self.storeURL)
                            self.removeFileAtURL(self.applicationStoresDirectory.URLByAppendingPathComponent(wal))
                            self.removeFileAtURL(self.applicationStoresDirectory.URLByAppendingPathComponent(shm))
                            
                        })
                    }
                }
            }
            
            self.context.performBlock({ () -> Void in
                self.importTimer.invalidate()
            })

        }
    
    }
    
    
    func loadNoniCloudStoreAsSeedStore() -> Bool {
        if seedInProgress {
            return false // Seed already in progress ...
        }
        if !self.unloadStore(seedStore) {
            return false // Failed to ensure _seedStore was removed prior to migration.
        }
        if !self.unloadStore(store) {
            return false // Failed to ensure _store was removed prior to migration.
        }
        
        let options = [NSReadOnlyPersistentStoreOption: true]
        do {
            seedStore = try seedCoordinator?.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: options)
            print("Successfully loaded Non-iCloud Store as Seed Store: \(seedStore)")
            return true
        } catch {
            print("Failed to load Non-iCloud Store as Seed Store. Error: \(error)")
            return false
        }
    }
    
    
    // MARK: - ICLOUD RESET
    
    func destroyAlliCloudDataForThisApplication() {
        
        if let path = iCloudStore?.URL?.path {
            if !NSFileManager.defaultManager().fileExistsAtPath(path) {
                return
            }
        }
        
        removeAllStoresFromCoordinator(coordinator!)
        removeAllStoresFromCoordinator(seedCoordinator!)
        coordinator = nil
        seedCoordinator = nil
        
        let options: [String: String] = [NSPersistentStoreUbiquitousContentNameKey: iCloudStoreFilename!]
        
        guard let url = iCloudStore?.URL else {
            return
        }
        
        do {
            try  NSPersistentStoreCoordinator.removeUbiquitousContentAndPersistentStoreAtURL(url, options: options)
        } catch {
            print("FAILED to destroy iCloud content at URL: \(iCloudStore?.URL)")
        }
        
    }
    
    
}
