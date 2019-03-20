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
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Product")
        let sortDescriptor = NSSortDescriptor(key: "productId", ascending: true)
        let sortDescriptors  = [sortDescriptor]
        fetchRequest.sortDescriptors = sortDescriptors
        
        self.frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: globalContext!, sectionNameKeyPath: nil, cacheName: "productCache")
        
        self.frc.delegate = self
        self.performFetch()
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "productCellId", for: indexPath as IndexPath)
        
        let product: Product = self.frc.object(at: indexPath as IndexPath) as! Product
        cell.textLabel?.text = product.productName
        cell.detailTextLabel?.text = product.productIntroduction
        
        return cell
    }

    @IBAction func addOneProduct(_ sender: AnyObject) {
        
        Product.insertCoreDataModel()
        
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
            try coreDataHelper?.deleteAllExistingObjectOfEntity("Product", ctx: globalContext!)
            NSFetchedResultsController<NSFetchRequestResult>.deleteCache(withName: "productCache")
            try self.frc.performFetch()
            tableView.reloadData()
        } catch {
            
        }
        
    }
    
    
}
