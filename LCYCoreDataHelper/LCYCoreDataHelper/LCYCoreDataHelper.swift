//
//  LCYCoreDataHelper.swift
//  G&L
//
//  Created by LiChunyu on 15/6/29.
//  Copyright (c) 2015年 hzwanqing. All rights reserved.
//

import Foundation
import CoreData
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


public final class LCYCoreDataHelper: NSObject, UIAlertViewDelegate {
    
    internal var importTimer: Timer!
    
    internal var iCloudStoreFilename: String?
    internal var seedInProgress: Bool = false
    
    fileprivate var sourceStoreFilename: String?
    internal var entitiesToCopy: [String]?
    public var selectedUniqueAttributes: [String: String]?
    
    internal var storeName: String!
    fileprivate var  migrationVC: LCYMigrationVC?
    fileprivate var model: NSManagedObjectModel?
    
    internal var coordinator: NSPersistentStoreCoordinator?
    fileprivate var sourceCoordinator: NSPersistentStoreCoordinator?
    internal var seedCoordinator: NSPersistentStoreCoordinator?
    
    
    public fileprivate(set) var parentContext: NSManagedObjectContext = {
        return NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    }()
    public fileprivate(set) var context: NSManagedObjectContext = {
        return NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    }()
    public fileprivate(set) var sourceContext: NSManagedObjectContext = {
        return NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    }()
    public fileprivate(set) var importContext: NSManagedObjectContext = {
        return NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    }()
    public fileprivate(set) var seedContext: NSManagedObjectContext = {
        return NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    }()
    
    
    internal var store: NSPersistentStore?
    internal var sourceStore: NSPersistentStore?
    internal var seedStore: NSPersistentStore?
    internal var iCloudStore: NSPersistentStore?
    
    //MARK: - PATHS
    lazy internal var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "org.leacode.TestCoreData" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy internal var applicationStoresDirectory: URL = {
        let storesDirectory: URL = self.applicationDocumentsDirectory.appendingPathComponent("Stores")
        var fileManager: FileManager = FileManager.default
        var error: NSError? = nil
        
        if fileManager.fileExists(atPath: storesDirectory.path) {
            do {
                try fileManager.createDirectory(at: storesDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("FAILED to create Stores directory")
            }
        }
        
        return storesDirectory
    }()
    
    lazy internal var storeURL: URL = {
        return self.applicationDocumentsDirectory.appendingPathComponent(self.storeName)
    }()
    
    lazy fileprivate var sourceStoreURL: URL? = {
        guard let fileName = self.sourceStoreFilename else {
            return nil
        }
        
        guard let path = Bundle.main.path(forResource: (fileName as NSString).deletingPathExtension, ofType: "momd") else {
            return nil
        }
        
        return URL(fileURLWithPath: path)
    }()
    
    // MARK: - Initial
    public convenience init(storeFileName: String, sourceStoreFileName: String? = nil, entitiesToCopy: [String]? = nil,selectedUniqueAttributes: [String: String]? = nil) throws {
        self.init()
        
        self.storeName = storeFileName
        self.selectedUniqueAttributes = selectedUniqueAttributes
        self.entitiesToCopy = entitiesToCopy
        parentContext.performAndWait { () -> Void in
            self.parentContext.persistentStoreCoordinator = self.coordinator
            self.parentContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        }
        
        context.parent = parentContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        if let sourceFileName = sourceStoreFileName {
            self.sourceStoreFilename = sourceFileName
            importContext.performAndWait({ () -> Void in
                self.importContext.parent = self.parentContext
                self.importContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                self.importContext.undoManager = nil
            })
            sourceCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model!)
            sourceContext.performAndWait { () -> Void in
                self.sourceContext.parent = self.parentContext
                self.sourceContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                self.sourceContext.undoManager = nil
            }
        }
        
        seedCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model!)
        seedContext.performAndWait { () -> Void in
            self.seedContext.persistentStoreCoordinator = self.seedCoordinator
            self.seedContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            self.seedContext.undoManager = nil // the default on iOS
        }
        listenForStoreChanges()
    }
    
    public required override init() {
        
        guard let mergedModel = NSManagedObjectModel.mergedModel(from: nil) else {
            return
        }
        model = mergedModel
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model!)
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
                    NSSQLitePragmasOption:["journal_mode": "DELETE"]] as [String : Any]
                store = try coordinator?.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: self.storeURL, options: options)
                print("Successfully add store")
            }
        } catch {
            print("Failed to add store, error: \(error)")
        }
    }
    
    public func loadSourceStore() throws {
        if sourceStore != nil {
            return
        }
        let options = [NSReadOnlyPersistentStoreOption: true]
        do {
             sourceStore = try sourceCoordinator?.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: sourceStoreURL!, options: options)
        } catch {
            print("failed to load sourceStore error: \(error)")
            return
        }
    }
    
    public func setupCoreData() throws {
        
        
        try self.setDefaultDataStoreAsInitialStore()
        try self.loadStore()
        try checkIfDefaultDataNeedsImporting()
        
        if store != nil && iCloudStore != nil {
            
        } else {
            
        }
        
        
        
//        try loadSourceStore()
//        sourceContext.performBlock { () -> Void in
//            do {
//                try self.sourceCoordinator?.migratePersistentStore(self.sourceStore!, toURL: self.storeURL, options: nil, withType: NSSQLiteStoreType)
//                self.context.performBlock({ () -> Void in
//                    self.somethingChanged()
//                })
//            } catch {
//                print("FAILED to migrate: \(error)")
//            }
//        }
//        
        
        
    }
    
    // MARK: - DATA IMPORT
    
    func setDefaultDataAsImportedForStore(_ aStore: NSPersistentStore) {
        
        var dictionary = aStore.metadata
        dictionary?["DefaultDataImported"] = true
        coordinator?.setMetadata(dictionary, for: aStore)
        
    }
    
    func setDefaultDataStoreAsInitialStore() throws {
        
        guard let fileName = self.sourceStoreFilename else {
            return
        }

        let fileManager = FileManager.default
        let home = NSHomeDirectory() as NSString
        /// 2、获得Documents路径，使用NSString对象的stringByAppendingPathComponent()方法拼接路径
        let docPath = home.appendingPathComponent("Documents") as NSString
        let filePath = docPath.appendingPathComponent(fileName)
        
        if !fileManager.fileExists(atPath: filePath) {
            guard let defaultDataURL =  Bundle.main.path(forResource: (fileName as NSString).deletingPathExtension, ofType: (fileName as NSString).pathExtension) else {
                return
            }
            try fileManager.copyItem(at: URL(string: defaultDataURL)!, to: storeURL)
        }
    
    }
    
    func isDefaultDataAlreadyImportedForStore(_ url: URL, type: String) -> Bool {
        
        do {
            let dictionary = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: type, at: url)
            let defaultDataAlreadyImported = (dictionary["DefaultDataImported"] as AnyObject).boolValue
            
            guard let isImported = defaultDataAlreadyImported else {
                return false
            }
            if !isImported {
                return false
            }
            return true
        } catch {
            return false
        }
        
    }
    
    func checkIfDefaultDataNeedsImporting() throws {
        if !self.isDefaultDataAlreadyImportedForStore(storeURL, type: NSSQLiteStoreType) {
            try deepCopyFromSourceStore()
        }
    }
    
    func importDefaultData() {
        
    }
    
    public func deepCopyFromSourceStore() throws {
        try loadSourceStore()
        guard let url = sourceStoreURL else {
            return
        }
        try deepCopyFromPersistentStore(url)
        try setDefaultDataStoreAsInitialStore()
        setDefaultDataAsImportedForStore(store!)
    }
    
    public func deepCopyFromPersistentStore(_ url: URL) throws {
        
        guard let attributes = selectedUniqueAttributes else {
            return
        }
        
        let importTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(LCYCoreDataHelper.somethingChanged), userInfo: nil, repeats: true)
        
        sourceContext.perform { () -> Void in
            
            let entitiesToCopy = ["User"]
            
            let importer = LCYCoreDataImporter(uniqueAttributes: attributes)
            do {
                try importer.deepCopyEntities(entitiesToCopy, fromContext: self.sourceContext, toContext: self.context)
                self.context.perform({ () -> Void in
                    importTimer.invalidate()
                    self.somethingChanged()
                })
            } catch {
            
            }
            
        }
        
    }
    
//    func somethingChanged() {
//        NSNotificationCenter.defaultCenter().postNotificationName("SometiongChanged", object: nil)
//    }
    
    
    //MARK: - SAVING
    public func saveContext() throws {
        
        try context.save()
                
    }
    
    public func backgroundSaveContext() throws {
        
        try self.saveContext()
        try parentContext.performOrThrow({
            if self.parentContext.hasChanges {
                try self.parentContext.save()
            }
        })
        
    }
    
    
    //MARK: - MIGRATION MANAGER
    func isMigrationNecessaryForStore(_ storeUrl: URL) throws -> Bool {
        if FileManager.default.fileExists(atPath: self.storeURL.path) {
            return false
        }
        
        do {
            let sourceMetadata: [String : AnyObject] = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeUrl) as [String : AnyObject]
            if let storeCoordinator = coordinator {
                let destinationModel: NSManagedObjectModel = storeCoordinator.managedObjectModel
                if destinationModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: sourceMetadata) {
                    return false
                }
            }
        } catch {
            return false
        }
        
        return true
    }
    
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "migrationProgress" {
            
            DispatchQueue.main.async(execute: { () -> Void in
                let progress = (change![NSKeyValueChangeKey.newKey] as AnyObject).floatValue
                if let progressValue = progress {
                    self.migrationVC?.progressView.progress = progressValue
                    let precentage = progressValue * 100
                    let string = "Migration Progress:\(precentage)%"
                    self.migrationVC?.label.text = string
                }
            })
            
        }
        
    }
    
    func replaceStore(_ oldStore: URL,withStore newStore: URL) throws -> Bool {
        var success = false
        
        do {
            try FileManager.default.removeItem(at: oldStore)
            
            try FileManager.default.moveItem(at: newStore, to: oldStore)
            success = true
            
        } catch {
            print("FAILED to replace store, error: \(error) ")
        }
        
        return success
    }
    
    func migrateStore(_ sourceStore: URL) throws -> Bool {
        var success = false
        
        // STEP 1 - Gather the Source, Destination and Mapping Model
        
        let sourceMetadata: [String: AnyObject]? = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: sourceStore) as [String : AnyObject]?
        
        var sourceModel: NSManagedObjectModel?
        if let metadata = sourceMetadata {
            
            sourceModel = NSManagedObjectModel.mergedModel(from: nil, forStoreMetadata: metadata)
            
        }
        
        let destinModel: NSManagedObjectModel? = model
        
        let mappingModel: NSMappingModel? = NSMappingModel(from: nil, forSourceModel: sourceModel, destinationModel: destinModel)
        
        // STEP 2 - Perform migration, assuming the mapping model isn't null
        if let _ = mappingModel {
            let migrationManager: NSMigrationManager = NSMigrationManager(sourceModel: sourceModel!, destinationModel: destinModel!)
            migrationManager.addObserver(self, forKeyPath: "migrationProgress", options: NSKeyValueObservingOptions.new, context: nil)
            
            let destinStore = self.applicationStoresDirectory.appendingPathComponent("Temp.sqlite")
            
            do {
                try migrationManager.migrateStore(from: sourceStore, sourceType: NSSQLiteStoreType, options: nil, with: mappingModel, toDestinationURL: destinStore, destinationType: NSSQLiteStoreType, destinationOptions: nil)
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
    
    func performBackgroundManagedMigrationForStore(_ storeURL: URL) throws {
        // Show migration progress view preventing the user from using the app
        let sb: UIStoryboard = UIStoryboard(name: "LCYCoreDataHelper", bundle: Bundle.main)
        
        migrationVC = sb.instantiateViewController(withIdentifier: "migration") as? LCYMigrationVC
        let sa: UIApplication = UIApplication.shared
        let nc: UIViewController? = sa.keyWindow?.rootViewController
        
        if let vc = migrationVC {
            nc?.present(vc, animated: false, completion: nil)
        }
        
        // Perform migration in the background, so it doesn't freeze the UI.
        // This way progress can be shown to the user
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            do {
                let done = try self.migrateStore(storeURL)
                
                if done {
                    DispatchQueue.main.async(execute: { () -> Void in
                        
                        do {
                            self.store = try self.coordinator?.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: self.storeURL, options: nil)
                            print("Successfully add ad migrated store: \(self.store)")
                        } catch {
                            
                        }
                        self.migrationVC?.dismiss(animated: false, completion: nil)
                        self.migrationVC = nil
                    })
                }
            } catch {
                
            }
        }
        
    }
    
    func showValidationError(_ anError: NSError?) {
        
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
//                let entity: String! = error.userInfo??["NSValidationErrorObject"]?!.entity.name!
                                
                var errorInfo: [AnyHashable: Any] = error.userInfo!!
                
                let property: String = errorInfo["NSValidationErrorKey"] as! String
                
                let code: Int = error.code!
                
                switch code {
                case NSValidationRelationshipDeniedDeleteError:
//                    txt = "\(entity) delete was denied because there are associate  \(property)\n(Error Code \(code)\n\n)"
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
    
    // MARK: - Operation of the store
    public func resetStore() throws {
        
        guard let store = coordinator?.persistentStore(for: storeURL) else {
            return
        }
        
        guard let coor = coordinator else {
            return
        }
        
        if #available(iOS 9, OSX 10.11, *) {
            try coor.destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType, options: nil)
        } else {
            let fm = FileManager()
            try coor.performAndWaitOrThrow{
                try coor.remove(store)
                try fm.removeItem(at: self.storeURL)
                try fm.removeItem(at: self.storeURL.appendingPathComponent("-shm"))
                try fm.removeItem(at: self.storeURL.appendingPathComponent("-wal"))
            }
        
        }
        
        // Setup a new stack
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            let newCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.model!)
            do {
                try newCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: self.storeURL, options: [
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


extension NSNull {
    func length() -> Int { return 0 }
    
    func integerValue() -> Int { return 0 }
    
    func floatValue() -> Float { return 0 };
    
    func componentsSeparatedByString(_ separator: String) -> [AnyObject] { return [AnyObject]() }
    
    func objectForKey(_ key: AnyObject) -> AnyObject? { return nil }
    
    func boolValue() -> Bool { return false }
}
