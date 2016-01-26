//
//  LCYCoreDataHelper.swift
//  G&L
//
//  Created by LiChunyu on 15/6/29.
//  Copyright (c) 2015年 hzwanqing. All rights reserved.
//

import Foundation
import CoreData

public final class LCYCoreDataHelper: NSObject {
    
    private var sourceStoreFilename: String?
    
    private var storeName: String!
    private var  migrationVC: LCYMigrationVC?
    private var model: NSManagedObjectModel?
    private var coordinator: NSPersistentStoreCoordinator?
    private var sourceCoordinator: NSPersistentStoreCoordinator?
    public private(set) var context: NSManagedObjectContext = {
        return NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
    }()
    public private(set) var sourceContext: NSManagedObjectContext = {
        return NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
    }()
    
    private var store: NSPersistentStore?
    private var sourceStore: NSPersistentStore?
    
    //MARK: - PATHS
    lazy private var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "org.leacode.TestCoreData" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy private var applicationStoresDirectory: NSURL = {
        let storesDirectory: NSURL = self.applicationDocumentsDirectory.URLByAppendingPathComponent("Stores")
        var fileManager: NSFileManager = NSFileManager.defaultManager()
        var error: NSError? = nil
        if let path = storesDirectory.path {
            if fileManager.fileExistsAtPath(path) {
                do {
                    try fileManager.createDirectoryAtURL(storesDirectory, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("FAILED to create Stores directory")
                }
            }
        }
        return storesDirectory
    }()
    
    lazy private var storeURL: NSURL = {
        return self.applicationDocumentsDirectory.URLByAppendingPathComponent(self.storeName)
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
    
    public convenience init(storeFileName: String) throws {
        self.init()
        
        self.storeName = storeFileName
        try loadStore()
    }
    
    public convenience init(sourceStoreFileName: String, storeFileName: String?) {
        self.init()
        
        sourceCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model!)
        sourceContext.performBlockAndWait { () -> Void in
            self.sourceContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            self.sourceContext.parentContext = self.context
            self.sourceContext.undoManager = nil
        }
        
    }
    
    public required override init() {
        
        model = NSManagedObjectModel.mergedModelFromBundles(nil)
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model!)
        context.persistentStoreCoordinator = coordinator
        
    }
    
    // MARK: - Setup Store
    
    func loadStore() throws {
        
        if store != nil {
            return
        }
        
        let useMigrationManager = false
        
        do {
            
            let isMigrationNecessary: Bool = try isMigrationNecessaryForStore(storeURL)
            
            if useMigrationManager && isMigrationNecessary {
                try performBackgroundManagedMigrationForStore(storeURL)
            } else {
                let options = [NSMigratePersistentStoresAutomaticallyOption: true,
                    NSInferMappingModelAutomaticallyOption: true,
                    NSSQLitePragmasOption:["journal_mode": "DELETE"]]
                
                store = try coordinator?.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: self.storeURL, options: options)
                
                print("Successfully add store")
            }
            
        } catch {
            print("Failed to add store, error: \(error)")
        }
        
    }
    
    func loadSourceStore() throws {
        if sourceStore != nil {
            return
        }
        
        let options = [NSReadOnlyPersistentStoreOption: true]
        sourceStore = try sourceCoordinator?.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: sourceStoreURL, options: options)
    }
    
    public func setupCoreData() throws {
        try self.loadStore()
    }
    
    //MARK: - SAVING
    public func saveContext() throws {
        
        try context.saveContextAndWait()
                
    }
    
    //MARK: - MIGRATION MANAGER
    func isMigrationNecessaryForStore(storeUrl: NSURL) throws -> Bool {
        if NSFileManager.defaultManager().fileExistsAtPath(self.storeURL.path!) {
            return false
        }
        
        do {
            let sourceMetadata: [String : AnyObject] = try NSPersistentStoreCoordinator.metadataForPersistentStoreOfType(NSSQLiteStoreType, URL: storeUrl)
            if let storeCoordinator = coordinator {
                let destinationModel: NSManagedObjectModel = storeCoordinator.managedObjectModel
                if destinationModel.isConfiguration(nil, compatibleWithStoreMetadata: sourceMetadata) {
                    return false
                }
            }
        } catch {
            return false
        }
        
        return true
    }
    
    
    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "migrationProgress" {
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let progress = change![NSKeyValueChangeNewKey]?.floatValue
                if let progressValue = progress {
                    self.migrationVC?.progressView.progress = progressValue
                    let precentage = progressValue * 100
                    let string = "Migration Progress:\(precentage)%"
                    self.migrationVC?.label.text = string
                }
            })
            
        }
        
    }
    
    func replaceStore(oldStore: NSURL,withStore newStore: NSURL) throws -> Bool {
        var success = false
        
        do {
            try NSFileManager.defaultManager().removeItemAtURL(oldStore)
            
            try NSFileManager.defaultManager().moveItemAtURL(newStore, toURL: oldStore)
            success = true
            
        } catch {
            print("FAILED to replace store, error: \(error) ")
        }
        
        return success
    }
    
    func migrateStore(sourceStore: NSURL) throws -> Bool {
        var success = false
        
        // STEP 1 - Gather the Source, Destination and Mapping Model
        
        let sourceMetadata: [String: AnyObject]? = try NSPersistentStoreCoordinator.metadataForPersistentStoreOfType(NSSQLiteStoreType, URL: sourceStore)
        
        var sourceModel: NSManagedObjectModel?
        if let metadata = sourceMetadata {
            
            sourceModel = NSManagedObjectModel.mergedModelFromBundles(nil, forStoreMetadata: metadata)
            
        }
        
        let destinModel: NSManagedObjectModel? = model
        
        let mappingModel: NSMappingModel? = NSMappingModel(fromBundles: nil, forSourceModel: sourceModel, destinationModel: destinModel)
        
        // STEP 2 - Perform migration, assuming the mapping model isn't null
        if let _ = mappingModel {
            let migrationManager: NSMigrationManager = NSMigrationManager(sourceModel: sourceModel!, destinationModel: destinModel!)
            migrationManager.addObserver(self, forKeyPath: "migrationProgress", options: NSKeyValueObservingOptions.New, context: nil)
            
            let destinStore = self.applicationStoresDirectory.URLByAppendingPathComponent("Temp.sqlite")
            
            do {
                try migrationManager.migrateStoreFromURL(sourceStore, type: NSSQLiteStoreType, options: nil, withMappingModel: mappingModel, toDestinationURL: destinStore, destinationType: NSSQLiteStoreType, destinationOptions: nil)
                success = true
            } catch {
                success = false
            }
            
            if success == true {
                // STEP 3 - Replace the old store with the new migrated store
                migrationManager.removeObserver(self, forKeyPath: "migrationProgress")
            }
        }
        return true
    }
    
    func performBackgroundManagedMigrationForStore(storeURL: NSURL) throws {
        // Show migration progress view preventing the user from using the app
        let sb: UIStoryboard = UIStoryboard(name: "LCYCoreDataHelper", bundle: NSBundle.mainBundle())
        
        migrationVC = sb.instantiateViewControllerWithIdentifier("migration") as? LCYMigrationVC
        let sa: UIApplication = UIApplication.sharedApplication()
        let nc: UIViewController? = sa.keyWindow?.rootViewController
        
        if let vc = migrationVC {
            nc?.presentViewController(vc, animated: false, completion: nil)
        }
        
        // Perform migration in the background, so it doesn't freeze the UI.
        // This way progress can be shown to the user
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
            
            do {
                let done = try self.migrateStore(storeURL)
                
                if done {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        do {
                            self.store = try self.coordinator?.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: self.storeURL, options: nil)
                            print("Successfully add ad migrated store: \(self.store)")
                        } catch {
                            
                        }
                        self.migrationVC?.dismissViewControllerAnimated(false, completion: nil)
                        self.migrationVC = nil
                    })
                }
            } catch {
                
            }
            
        })
    }
    
    func showValidationError(anError: NSError?) {
        
        let errors: [AnyObject]? = nil
        var txt = ""
        if let error = anError {
            if error.domain == NSCocoaErrorDomain {
                if error.code == NSValidationMultipleErrorsError {
                    _ = error.userInfo[NSDetailedErrorsKey] as? [AnyObject]
                }
            }
        }
        
        // Display the error(s)
        if errors != nil && errors?.count > 0 {
            for error in errors! {
                let entity: String! = error.userInfo??["NSValidationErrorObject"]?!.entity.name!
                
                var errorInfo: [NSObject: AnyObject] = error.userInfo!!
                
                let property: String = errorInfo["NSValidationErrorKey"] as! String
                
                let code: Int = error.code!
                
                switch code {
                case NSValidationRelationshipDeniedDeleteError:
                    txt = "\(entity) delete was denied because there are associate  \(property)\n(Error Code \(code)\n\n)"
                    break;
                case NSValidationRelationshipLacksMinimumCountError:
                    txt = "the '\(property)' relationship count is too small (Code \(code)). "
                    break;
                case NSValidationRelationshipExceedsMaximumCountError:
                    txt = "the '\(property)' relationship count is too large (Code \(code)). "
                    break;
                case NSValidationMissingMandatoryPropertyError:
                    txt = "the '\(property)' property is missing (Code \(code)). "
                    break;
                case NSValidationNumberTooSmallError:
                    txt = "the '\(property)' number is too small (Code \(code)). "
                    break;
                case NSValidationNumberTooLargeError:
                    txt = "the '\(property)' number is too large (Code \(code)). "
                    break;
                case NSValidationDateTooSoonError:
                    txt = "the '\(property)' date is too soon (Code \(code)). "
                    break;
                case NSValidationDateTooLateError:
                    txt = "the '\(property)' date is too late (Code \(code)). "
                    break;
                case NSValidationInvalidDateError:
                    txt = "the '\(property)' date is invalid (Code \(code)). "
                    break;
                case NSValidationStringTooLongError:
                    txt = "the '\(property)' text is too long (Code \(code)). "
                    break;
                case NSValidationStringTooShortError:
                    txt = "the '\(property)' text is too short (Code \(code)). "
                    break;
                case NSValidationStringPatternMatchingError:
                    txt = "the '\(property)' text doesn't match the specified pattern (Code \(code)). "
                    break;
                case NSManagedObjectValidationError:
                    txt = "generated validation error (Code \(code)). "
                    break;
                    
                default:
                    txt = "Unhandled error code \(code) in showValidationError method"
                    break;
                }
            }
            // display error message txt message
            let message = "\(txt)Please double-tap the home button and close this application by swiping the application screenshot upwards"
            let alertView: UIAlertView = UIAlertView(title: "Validation Error", message: message, delegate: nil, cancelButtonTitle: nil)
            alertView.show()
        }
        
    }
    
//    func deepCopyFromPersistentStore(url: NSURL) {
//        let importTimer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: Selector("somethingChanged"), userInfo: nil, repeats: true)
//        
//        sourceContext.performBlock { () -> Void in
//            var entitysToCopy = ["LocationAtHome", "LocationAtShop"]
//            
//            
////            CoreDataImporter *importer = [[CoreDataImporter alloc]
////                initWithUniqueAttributes:[self selectedUniqueAttributes]];
////            
////            [importer deepCopyEntities:entitiesToCopy
////                fromContext:_sourceContext
////                toContext:_importContext];
////            
////            [_context performBlock:^{
////                // Stop periodically refreshing the interface
////                [_importTimer invalidate];
////                
////                // Tell the interface to refresh once import completes
////                [self somethingChanged];
//            
//        }
//        
//    }
//    
 
    
    // MARK: - Operation of the store
    public func resetStore() throws {
        
        guard let store = coordinator?.persistentStoreForURL(storeURL) else {
            return
        }
        
        guard let coor = coordinator else {
            return
        }
        
        if #available(iOS 9, OSX 10.11, *) {
            try coor.destroyPersistentStoreAtURL(storeURL, withType: NSSQLiteStoreType, options: nil)
        } else {
            let fm = NSFileManager()
            try coor.performAndWaitOrThrow{
                try coor.removePersistentStore(store)
                try fm.removeItemAtURL(self.storeURL)
                try fm.removeItemAtURL(self.storeURL.URLByAppendingPathComponent("-shm"))
                try fm.removeItemAtURL(self.storeURL.URLByAppendingPathComponent("-wal"))
            }
        
        }
        
        // Setup a new stack
        
        let backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
        dispatch_async(backgroundQueue) {
            let newCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.model!)
            do {
                try newCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: self.storeURL, options: [
                    NSMigratePersistentStoresAutomaticallyOption: true,
                    NSInferMappingModelAutomaticallyOption: true,
                    NSSQLitePragmasOption: ["journal_mode": "WAL"]
                    ])
                self.coordinator = newCoordinator
            } catch {
            
            }
            
        }
        
    }
    
    
}

