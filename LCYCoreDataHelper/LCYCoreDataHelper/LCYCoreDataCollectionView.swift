//
//  LCYCoreDataCollectionView.swift
//  monsoon
//
//  Created by LiChunyu on 15/11/24.
//
//

import UIKit
import CoreData

public class LCYCoreDataCollectionView: UICollectionView, NSFetchedResultsControllerDelegate {

    public var frc:NSFetchedResultsController!
    
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        
        
        
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        
        
    }
    
    //MARK: - FETCHING
    
    public func performFetch() throws {
        frc.managedObjectContext.performBlockAndWait { () -> Void in
            
            do {
                try self.frc.performFetch()
            } catch {
                print("Failed to perform fetch")
            }
            
            self.reloadData()
        }
    }
    
    
    // MARK: UICollectionViewDataSource
    
    override public func numberOfSections() -> Int {
        
        var numberOfSections: Int = 0
        if let sections = self.frc.sections {
            numberOfSections = sections.count
        }
        return numberOfSections
        
    }
    
    override public func numberOfItemsInSection(section: Int) -> Int {
        var numberOfRow: Int = 0
        if let sections = self.frc.sections {
            numberOfRow = sections[section].numberOfObjects
        }
        return numberOfRow
    }
    
    
    //MARK: - DELEGATE: NSFetchedResultsController
    
    public func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case NSFetchedResultsChangeType.Insert:
            
            self.insertSections(NSIndexSet(index: sectionIndex))
            break;
        case NSFetchedResultsChangeType.Delete:
            self.deleteSections(NSIndexSet(index: sectionIndex))
            break;
        default:
            break;
        }
    }
    
    public func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
 
        switch type {
        case NSFetchedResultsChangeType.Insert:
            if let newPath = newIndexPath {
                self.insertItemsAtIndexPaths([newPath])
            }
            break;
        case NSFetchedResultsChangeType.Delete:
            if let idxPath = indexPath {
                self.deleteItemsAtIndexPaths([idxPath])
            }
            break;
        case NSFetchedResultsChangeType.Update:
            if let newPath = newIndexPath {
                if let idxPath = indexPath {
                    self.deleteItemsAtIndexPaths([idxPath])
                    self.insertItemsAtIndexPaths([newPath])
                }
            } else {
                if let idxPath = indexPath {
                    self.reloadItemsAtIndexPaths([idxPath])
                }
            }
            break;
        case NSFetchedResultsChangeType.Move:
            if let newPath = newIndexPath {
                if let idxPath = indexPath {
                    self.deleteItemsAtIndexPaths([idxPath])
                    self.insertItemsAtIndexPaths([newPath])
                }
            }
            break;
        }
        
    }

    
}
