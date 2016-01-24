//
//  CoreDataTableViewController.swift
//  LCYCoreDataHelperExample
//
//  Created by LiChunyu on 16/1/24.
//  Copyright © 2016年 leacode. All rights reserved.
//

import UIKit
import LCYCoreDataHelper
import CoreData

class CoreDataTableViewController: LCYCoreDataTVC {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let fetchRequest = NSFetchRequest(entityName: "Product")
        let sortDescriptor = NSSortDescriptor(key: "productId", ascending: true)
        let sortDescriptors  = [sortDescriptor]
        fetchRequest.sortDescriptors = sortDescriptors
        
        self.frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: globalContext!, sectionNameKeyPath: nil, cacheName: "productCache")
        
        self.frc.delegate = self
        self.performFetch()
        
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("productCellId", forIndexPath: indexPath)

        let product: Product = self.frc.objectAtIndexPath(indexPath) as! Product
        cell.textLabel?.text = product.productName
        cell.detailTextLabel?.text = product.productIntroduction

        return cell
    }
    
    @IBAction func addOneProduct(sender: AnyObject) {
        
        Product.insertCoreDataModel()
        
    }

    @IBAction func deleteLast(sender: AnyObject) {
        
        if self.frc.fetchedObjects?.count > 0 {
            globalContext?.deleteObject((self.frc.fetchedObjects?.last)! as! NSManagedObject)
        }
        
    }
    
    @IBAction func deleteAll(sender: AnyObject) {
        
        do {
            try coreDataHelper?.removeAll("Product")
            NSFetchedResultsController.deleteCacheWithName("productCache")
            try self.frc.performFetch()
            tableView.reloadData()
        } catch {
            
        }
        
    }
    
    
}
