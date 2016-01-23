//
//  LCYCoreDataTVC.swift
//  GlobalAlarm2
//
//  Created by leacode on 14/11/1.
//  Copyright (c) 2014年 leacode. All rights reserved.
//

import UIKit
import CoreData

public class LCYCoreDataTVC: UITableViewController, NSFetchedResultsControllerDelegate {
    
    public var frc:NSFetchedResultsController!
    
    //MARK: - FETCHING
    public func performFetch() {
        frc.managedObjectContext.performBlockAndWait { () -> Void in
            
            do {
                try self.frc.performFetch()
            } catch {
                print("Failed to perform fetch")
            }

            self.tableView.reloadData()
        }
    }
    
    //MARK: - DATASOURCE: UITableView
    
    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberOfRow: Int = 0
        if let sections = self.frc.sections {
            numberOfRow = sections[section].numberOfObjects
        }
        return numberOfRow
    }
    
    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var numberOfSections: Int = 0
        if let sections = self.frc.sections {
            numberOfSections = sections.count
        }
        return numberOfSections
    }
    
    override public func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return self.frc.sectionForSectionIndexTitle(title, atIndex: index)
    }

    override public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let name: String? = nil

        
        return name
    }
    
    public override func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        return self.frc.sectionIndexTitles
    }
    
    //MARK: - DELEGATE: NSFetchedResultsController
    public func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }
    
    public func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case NSFetchedResultsChangeType.Insert:
            self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: UITableViewRowAnimation.Fade)
            break;
        case NSFetchedResultsChangeType.Delete:
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: UITableViewRowAnimation.Fade)
            break;
        default:
            break;
        }
    }

    public func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        _ = self.tableView
        switch type {
        case NSFetchedResultsChangeType.Insert:
            if let newPath = newIndexPath {
                self.tableView.insertRowsAtIndexPaths([newPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            }
            break;
        case NSFetchedResultsChangeType.Delete:
            if let idxPath = indexPath {
                self.tableView.deleteRowsAtIndexPaths([idxPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            }
            break;
        case NSFetchedResultsChangeType.Update:
            if let newPath = newIndexPath {
                if let idxPath = indexPath {
                    self.tableView.deleteRowsAtIndexPaths([idxPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                    self.tableView.insertRowsAtIndexPaths([newPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                }
            } else {
                if let idxPath = indexPath {
                    self.tableView.reloadRowsAtIndexPaths([idxPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                }
            }
            break;
        case NSFetchedResultsChangeType.Move:
            if let newPath = newIndexPath {
                if let idxPath = indexPath {
                    self.tableView.deleteRowsAtIndexPaths([idxPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                    self.tableView.insertRowsAtIndexPaths([newPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                }
            }
            break;
        }
        
    }
    
    
   
}
