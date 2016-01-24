
//
//  LCYCoreDataTableView.swift
//  LCYCoreDataHelper
//
//  Created by LiChunyu on 16/1/24.
//  Copyright © 2016年 leacode. All rights reserved.
//

import UIKit
import CoreData

public class LCYCoreDataTableView: UITableView, NSFetchedResultsControllerDelegate {

    public var frc:NSFetchedResultsController!
    
      override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //MARK: - FETCHING
    public func performFetch() {
        frc.managedObjectContext.performBlockAndWait { () -> Void in
            do {
                try self.frc.performFetch()
            } catch {
                print("Failed to perform fetch")
            }
            
            self.reloadData()
        }
    }
    
    //MARK: - DATASOURCE: UITableView
    
    
    
    public override func numberOfRowsInSection(section: Int) -> Int {
        var numberOfRow: Int = 0
        if let sections = self.frc.sections {
            numberOfRow = sections[section].numberOfObjects
        }
        return numberOfRow
    }
    
    public func numberOfSectionsInTableView() -> Int {
        var numberOfSections: Int = 0
        if let sections = self.frc.sections {
            numberOfSections = sections.count
        }
        return numberOfSections
    }
    
    public func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return self.frc.sectionForSectionIndexTitle(title, atIndex: index)
    }
    
    public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let name: String? = nil
        
        
        return name
    }
    
    public func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        return self.frc.sectionIndexTitles
    }
    
    //MARK: - DELEGATE: NSFetchedResultsController
    public func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.beginUpdates()
    }
    
    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.endUpdates()
    }
    
    public func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case NSFetchedResultsChangeType.Insert:
            self.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: UITableViewRowAnimation.Fade)
            break;
        case NSFetchedResultsChangeType.Delete:
            self.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: UITableViewRowAnimation.Fade)
            break;
        default:
            break;
        }
    }
    
    public func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case NSFetchedResultsChangeType.Insert:
            if let newPath = newIndexPath {
                self.insertRowsAtIndexPaths([newPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            }
            break;
        case NSFetchedResultsChangeType.Delete:
            if let idxPath = indexPath {
                self.deleteRowsAtIndexPaths([idxPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            }
            break;
        case NSFetchedResultsChangeType.Update:
            if let newPath = newIndexPath {
                if let idxPath = indexPath {
                    self.deleteRowsAtIndexPaths([idxPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                    self.insertRowsAtIndexPaths([newPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                }
            } else {
                if let idxPath = indexPath {
                    self.reloadRowsAtIndexPaths([idxPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                }
            }
            break;
        case NSFetchedResultsChangeType.Move:
            if let newPath = newIndexPath {
                if let idxPath = indexPath {
                    self.deleteRowsAtIndexPaths([idxPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                    self.insertRowsAtIndexPaths([newPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                }
            }
            break;
        }
        
    }
    

}
