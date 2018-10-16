
//
//  CoreDataCollectionViewControllerExample.swift
//  LCYCoreDataHelperExample
//
//  Created by LiChunyu on 16/1/25.
//  Copyright © 2016年 leacode. All rights reserved.
//

import UIKit
import LCYCoreDataHelper
import CoreData

private let reuseIdentifier = "Cell"

class CoreDataCollectionViewControllerExample: LCYCoreDataCVC {

    override func viewDidLoad() {
        super.viewDidLoad()

        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "User")
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
        let sortDescriptors  = [sortDescriptor]
        fetchRequest.sortDescriptors = sortDescriptors
        
        self.frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: globalContext!, sectionNameKeyPath: nil, cacheName: "UserCache")
        self.frc.delegate = self
        
        do {
            try self.performFetch()
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! UserCollectionViewCell
        
        let user: User? = self.frc.object(at: indexPath as IndexPath) as? User
        cell.usernameLabel.text = user?.username ?? ""
        
        return cell
    }
    
    // MRK: - CRUD
    @IBAction func addNewItem(_ sender: AnyObject) {
        if (self.frc.fetchedObjects?.count)! > 0 {
            let user = (self.frc.fetchedObjects?.last)! as! User
            User.i = user.id + 1
        }
        User.insertCoreDataModel()
    }
        
    @IBAction func deleteLast(_ sender: AnyObject) {
        
        if let object = frc.fetchedObjects?.last, let context = globalContext {
            context.delete(object as! NSManagedObject)
            do {
                try coreDataHelper?.backgroundSaveContext()
            } catch {
                fatalError("Failure to save context: \(error)")
            }
        }
        
    }
    
    @IBAction func deleteAll(_ sender: AnyObject) {
        do {
            try coreDataHelper?.deleteAllExistingObjectOfEntity("User", ctx: globalContext!)
            NSFetchedResultsController<NSFetchRequestResult>.deleteCache(withName: "UserCache")
            try self.performFetch()
        } catch {
            
        }
    }

}
