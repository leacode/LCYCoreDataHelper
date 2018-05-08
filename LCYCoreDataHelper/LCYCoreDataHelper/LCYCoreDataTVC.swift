//
//  LCYCoreDataTVC.swift
//  GlobalAlarm2
//
//  Created by leacode on 14/11/1.
//  Copyright (c) 2014年 leacode. All rights reserved.
//

import UIKit
import CoreData

open class LCYCoreDataTVC: UITableViewController, NSFetchedResultsControllerDelegate {
    
    open var frc:NSFetchedResultsController<NSFetchRequestResult>!
    
    //MARK: - FETCHING
    open func performFetch() {
        frc.managedObjectContext.performAndWait { () -> Void in
            
            do {
                try self.frc.performFetch()
            } catch {
                print("Failed to perform fetch")
            }

            self.tableView.reloadData()
        }
    }
    
    //MARK: - DATASOURCE: UITableView
    
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberOfRow: Int = 0
        if let sections = self.frc.sections {
            numberOfRow = sections[section].numberOfObjects
        }
        return numberOfRow
    }
    
    override open func numberOfSections(in tableView: UITableView) -> Int {
        var numberOfSections: Int = 0
        if let sections = self.frc.sections {
            numberOfSections = sections.count
        }
        return numberOfSections
    }
    
    override open func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return self.frc.section(forSectionIndexTitle: title, at: index)
    }

    override open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let name: String? = nil

        
        return name
    }
    
    open override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return self.frc.sectionIndexTitles
    }
    
    //MARK: - DELEGATE: NSFetchedResultsController
    open func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    open func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
    
    open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case NSFetchedResultsChangeType.insert:
            self.tableView.insertSections(IndexSet(integer: sectionIndex), with: UITableViewRowAnimation.fade)
            break;
        case NSFetchedResultsChangeType.delete:
            self.tableView.deleteSections(IndexSet(integer: sectionIndex), with: UITableViewRowAnimation.fade)
            break;
        default:
            break;
        }
    }

    open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        _ = self.tableView
        switch type {
        case NSFetchedResultsChangeType.insert:
            if let newPath = newIndexPath {
                self.tableView.insertRows(at: [newPath], with: UITableViewRowAnimation.automatic)
            }
            break;
        case NSFetchedResultsChangeType.delete:
            if let idxPath = indexPath {
                self.tableView.deleteRows(at: [idxPath], with: UITableViewRowAnimation.automatic)
            }
            break;
        case NSFetchedResultsChangeType.update:
            if let newPath = newIndexPath {
                if let idxPath = indexPath {
                    self.tableView.deleteRows(at: [idxPath], with: UITableViewRowAnimation.automatic)
                    self.tableView.insertRows(at: [newPath], with: UITableViewRowAnimation.automatic)
                }
            } else {
                if let idxPath = indexPath {
                    self.tableView.reloadRows(at: [idxPath], with: UITableViewRowAnimation.automatic)
                }
            }
            break;
        case NSFetchedResultsChangeType.move:
            if let newPath = newIndexPath {
                if let idxPath = indexPath {
                    self.tableView.deleteRows(at: [idxPath], with: UITableViewRowAnimation.automatic)
                    self.tableView.insertRows(at: [newPath], with: UITableViewRowAnimation.automatic)
                }
            }
            break;
        }
        
    }
    
    
   
}
