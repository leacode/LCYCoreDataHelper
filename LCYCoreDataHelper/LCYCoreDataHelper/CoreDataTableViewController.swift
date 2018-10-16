//
//  CoreDataTableViewController.swift
//  LCYCoreDataHelper
//
//  Created by leacode on 2018/9/2.
//  Copyright © 2018 leacode. All rights reserved.
//

import Foundation
import CoreData

class CoreDataTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, CoreDataFetchedResultsController {
    
    func reloadData() {
        
    }
    
    
    
    var frc: NSFetchedResultsController<NSFetchRequestResult>!
    
    var entity: String!
    
    var cacheName: String?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    
    
}
