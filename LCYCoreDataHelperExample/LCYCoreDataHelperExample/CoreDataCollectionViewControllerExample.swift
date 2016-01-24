
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

        let fetchRequest = NSFetchRequest(entityName: "User")
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

   
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! UserCollectionViewCell
    
        let user: User = self.frc.objectAtIndexPath(indexPath) as! User
        cell.usernameLabel.text = user.username
    
        return cell
    }
    
    
    // MRK: - CRUD
    
    @IBAction func addNewItem(sender: AnyObject) {
        if self.frc.fetchedObjects?.count > 0 {
            let user = (self.frc.fetchedObjects?.last)! as! User
            User.i = user.id + 1
        }
        User.insertCoreDataModel()
        
    }
    
    
    @IBAction func deleteLast(sender: AnyObject) {
        
        if self.frc.fetchedObjects?.count > 0 {
            globalContext?.deleteObject((self.frc.fetchedObjects?.last)! as! NSManagedObject)
        }
        
    }
    
    @IBAction func deleteAll(sender: AnyObject) {
        
        do {
            try coreDataHelper?.removeAll("User")
            NSFetchedResultsController.deleteCacheWithName("UserCache")
            try self.frc.performFetch()
            collectionView!.reloadData()
        } catch {
            
        }
        
    }



}
