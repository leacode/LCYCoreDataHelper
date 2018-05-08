//
//  ImportedDataViewController.swift
//  LCYCoreDataHelperExample
//
//  Created by LiChunyu on 16/1/30.
//  Copyright © 2016年 leacode. All rights reserved.
//

import UIKit
import LCYCoreDataHelper
import CoreData

class ImportedDataViewController:UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet weak var tableView: LCYCoreDataTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "User")
        fetchRequest.sort("id", ascending: true)
        
        tableView.frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: coreDataHelper!.importContext, sectionNameKeyPath: nil, cacheName: "UserCache")
        tableView.frc.delegate = tableView
        
        tableView.performFetch()
    
        //
//        
//        let fetchRequest = NSFetchRequest(entityName: "User")
//        let sortDescriptor = NSSortDescriptor(key: "User", ascending: true)
//        let sortDescriptors  = [sortDescriptor]
//        fetchRequest.sortDescriptors = sortDescriptors
//        
//        self.tableView.frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: (coreDataHelper?.importContext)!, sectionNameKeyPath: nil, cacheName: "userCache")
//        
//        self.tableView.frc.delegate = self.tableView
//        self.tableView.performFetch()
        
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCellId", for: indexPath as IndexPath)
        
        let user: User = self.tableView.frc.object(at: indexPath as IndexPath) as! User
        cell.textLabel?.text = user.username
//        
//        let product: Product = self.tableView.frc.objectAtIndexPath(indexPath) as! Product
//        cell.textLabel?.text = product.productName
//        cell.detailTextLabel?.text = product.productIntroduction
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    
}
