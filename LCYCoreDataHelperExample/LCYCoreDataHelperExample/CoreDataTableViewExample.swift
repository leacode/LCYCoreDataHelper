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

        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Product")
        let sortDescriptor = NSSortDescriptor(key: "productId", ascending: true)
        let sortDescriptors  = [sortDescriptor]
        fetchRequest.sortDescriptors = sortDescriptors
        
        self.tableView.frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: globalContext!, sectionNameKeyPath: nil, cacheName: "productCache")
        
        self.tableView.frc.delegate = self.tableView
        self.tableView.performFetch()
        
    }
    
    private func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // 'self' is needed here
        return self.tableView.numberOfSectionsInTableView()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 'self' is needed here
        return self.tableView.numberOfRows(inSection: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "productCellId", for: indexPath as IndexPath)
        
        let product: Product = self.tableView.frc.object(at: indexPath as IndexPath) as! Product
        cell.textLabel?.text = product.productName
        cell.detailTextLabel?.text = product.productIntroduction
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    // MARK: - Actions
    
    @IBAction func addOneProduct(_ sender: AnyObject) {
        Product.insertCoreDataModel()
    }
    
    @IBAction func deleteLast(_ sender: AnyObject) {
        
        if let object = self.tableView.frc.fetchedObjects?.last as? NSManagedObject, let context = globalContext {
            coreDataHelper?.delete(object: object, ctx: context)
        }
    }
    
    @IBAction func deleteAll(_ sender: AnyObject) {
        
        do {
            try coreDataHelper?.deleteAllExistingObjectOfEntity("Product", ctx: globalContext!)
            NSFetchedResultsController<NSFetchRequestResult>.deleteCache(withName: "productCache")
            try self.tableView.frc.performFetch()
            tableView.reloadData()
        } catch {
            
        }
        
    }


   
}
