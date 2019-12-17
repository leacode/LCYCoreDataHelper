
//
//  LCYCoreDataHelperICloud.swift
//  LCYCoreDataHelper
//
//  Created by LiChunyu on 16/2/5.
//  Copyright © 2016年 leacode. All rights reserved.
//

import UIKit
import CoreData

public extension LCYCoreDataHelper {
    
//    - (NSURL *)iCloudStoreURL {
//    if (debug==1) {
//    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
//    }
//    return [[self applicationStoresDirectory]
//    URLByAppendingPathComponent:iCloudStoreFilename];
//    }
    
    func iCloudStoreURL() -> URL? {
        guard let filename = iCloudStoreFilename else {
            return nil
        }
        return self.applicationStoresDirectory.appendingPathComponent(filename)
    }
    
    func iCloudAccountIsSignedIn() -> Bool {
        
        guard let token = FileManager.default.ubiquityIdentityToken else {
            return false
        }
        print("** iCloud is SIGNED IN with token '\(token)' **")
        return true
        
    }
    
    func loadiCloudStore(_ needAlert: Bool = false) throws -> Bool {
        if iCloudStore != nil {
            // Don’t load iCloud store if it’s already loaded
            return true
        }
        let options: [AnyHashable: Any] = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true, NSPersistentStoreUbiquitousContentNameKey: self.storeName!]
        do {
            iCloudStore = try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: iCloudStoreURL(), options: options)
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
        let dc = NotificationCenter.default
        dc.addObserver(self, selector: #selector(LCYCoreDataHelper.storesWillChange(_:)), name: NSNotification.Name.NSPersistentStoreCoordinatorStoresWillChange, object: self.coordinator)
        dc.addObserver(self, selector: #selector(LCYCoreDataHelper.storesDidChange(_:)), name: NSNotification.Name.NSPersistentStoreCoordinatorStoresDidChange, object: self.coordinator)
        dc.addObserver(self, selector: #selector(LCYCoreDataHelper.persistentStoreDidImportUbiquitiousContentChanges(_:)), name: NSNotification.Name.NSPersistentStoreDidImportUbiquitousContentChanges, object: self.coordinator)
    }
    
    @objc func storesWillChange(_ n: Notification) {
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
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "SomethingChanged"), object: nil)
        } catch {
            print("save changes error: \(error)")
        }
    }
    
    @objc func storesDidChange(_ n: Notification) {
         NotificationCenter.default.post(name: Notification.Name(rawValue: "SomethingChanged"), object: nil)
    }
    
    @objc func persistentStoreDidImportUbiquitiousContentChanges(_ n: Notification) {
        context.perform { () -> Void in
            self.context.mergeChanges(fromContextDidSave: n)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "SomethingChanged"), object: nil)
        }
    }
    
    func iCloudEnabledByUser() -> Bool {
        UserDefaults.standard.synchronize()
        if let icloudEnabled = (UserDefaults.standard.object(forKey: "iCloudEnabled") as AnyObject).boolValue {
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
    
    @objc(alertView:clickedButtonAtIndex:) func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if alertView.tag == 1 { // merge icloud
            
            if buttonIndex == alertView.firstOtherButtonIndex {
                do {
                    try self.mergeNoniCloudDataWithiCloud()
                } catch {
                    
                }
            }
            
        }
    }

//    @objc(alertView:clickedButtonAtIndex:) public func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
//        
//        
//        
//    }
    
    func mergeNoniCloudDataWithiCloud() throws {
        
        guard let attributes = selectedUniqueAttributes else {
            return
        }
        
        guard let entities = entitiesToCopy else {
            return
        }
        
        importTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: (#selector(LCYCoreDataHelper.somethingChanged as (LCYCoreDataHelper) -> () -> ())), userInfo: nil, repeats: true)
        
        try seedContext.performOrThrow {
            
            if self.loadNoniCloudStoreAsSeedStore() {
                print("*** STARTED DEEP COPY FROM NON-ICLOUD STORE TO ICLOUD STORE ***")
                
                let importer = LCYCoreDataImporter(uniqueAttributes: attributes)
                try importer.deepCopyEntities(entities, fromContext: self.seedContext, toContext: self.context)
                self.context.perform { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "SomethingChanged"), object: nil)
                    print("*** FINISHED DEEP COPY FROM NON-ICLOUD STORE TO ICLOUD STORE ***")
                    print("*** REMOVING OLD NON-ICLOUD STORE ***")
                    if self.unloadStore(self.seedStore) {
                        self.context.perform({ () -> Void in
                            // Tell the interface to refresh once import completes
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "SomethingChanged"), object: nil)
                            
                            // Remove migrated store
                            let wal = self.storeName + "-wal"
                            let shm = self.storeName + "-shm"
                            self.removeFileAtURL(self.storeURL)
                            self.removeFileAtURL(self.applicationStoresDirectory.appendingPathComponent(wal))
                            self.removeFileAtURL(self.applicationStoresDirectory.appendingPathComponent(shm))
                            
                        })
                    }
                }
            }
            
            self.context.perform({ () -> Void in
                self.importTimer.invalidate()
            })

        }
    
    }
    
    @objc func somethingChanged() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "SomethingChanged"), object: nil)
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
            seedStore = try seedCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL as URL, options: options)
            print("Successfully loaded Non-iCloud Store as Seed Store: \(String(describing: seedStore))")
            return true
        } catch {
            print("Failed to load Non-iCloud Store as Seed Store. Error: \(error)")
            return false
        }
    }
    
    
    // MARK: - ICLOUD RESET
    
    func destroyAlliCloudDataForThisApplication() {
        
        if let path = iCloudStore?.url?.path {
            if !FileManager.default.fileExists(atPath: path) {
                return
            }
        }
        
        removeAllStoresFromCoordinator(coordinator)
        removeAllStoresFromCoordinator(seedCoordinator)
        
        let options: [String: String] = [NSPersistentStoreUbiquitousContentNameKey: iCloudStoreFilename!]
        
        guard let url = iCloudStore?.url else {
            return
        }
        
        do {
            try  NSPersistentStoreCoordinator.removeUbiquitousContentAndPersistentStore(at: url, options: options)
        } catch {
            print("FAILED to destroy iCloud content at URL: \(String(describing: iCloudStore?.url))")
        }
        
    }
    
    
}
