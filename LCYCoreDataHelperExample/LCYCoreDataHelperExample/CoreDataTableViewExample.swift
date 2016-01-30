//
//  CoreDataTableViewShowcase.swift
//  LCYCoreDataHelperExample
//
//  Created by LiChunyu on 16/1/24.
//  Copyright © 2016年 leacode. All rights reserved.
//

import UIKit
import LCYCoreDataHelper
import CoreData

class CoreDataTableViewExample: UIViewController, UITableViewDelegate, UITableViewDataSource {

    
    @IBOutlet weak var tableView: LCYCoreDataTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let fetchRequest = NSFetchRequest(entityName: "Product")
        let sortDescriptor = NSSortDescriptor(key: "productId", ascending: true)
        let sortDescriptors  = [sortDescriptor]
        fetchRequest.sortDescriptors = sortDescriptors
        
        self.tableView.frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: globalContext!, sectionNameKeyPath: nil, cacheName: "productCache")
        
        self.tableView.frc.delegate = self.tableView
        self.tableView.performFetch()
        
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // 'self' is needed here
        return self.tableView.numberOfSectionsInTableView()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 'self' is needed here
        return self.tableView.numberOfRowsInSection(section)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("productCellId", forIndexPath: indexPath)
        
        let product: Product = self.tableView.frc.objectAtIndexPath(indexPath) as! Product
        cell.textLabel?.text = product.productName
        cell.detailTextLabel?.text = product.productIntroduction
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    // MARK: - Actions
    
    @IBAction func addOneProduct(sender: AnyObject) {
        Product.insertCoreDataModel()
    }
    
    @IBAction func deleteLast(sender: AnyObject) {
        
        if self.tableView.frc.fetchedObjects?.count > 0 {
            globalContext?.deleteObject((self.tableView.frc.fetchedObjects?.last)! as! NSManagedObject)
        }
        
    }
    
    @IBAction func deleteAll(sender: AnyObject) {
        
        do {
            try coreDataHelper?.deleteAllExistingObjectOfEntity("Product", ctx: globalContext!)
            NSFetchedResultsController.deleteCacheWithName("productCache")
            try self.tableView.frc.performFetch()
            tableView.reloadData()
        } catch {
            
        }
        
    }


   
}
