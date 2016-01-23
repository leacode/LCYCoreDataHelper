//
//  LCYCoreDataCVC.swift
//  GlobalAlarm2
//
//  Created by leacode on 15/1/17.
//  Copyright (c) 2015年 leacode. All rights reserved.
//

import UIKit
import CoreData

let reuseIdentifier = "Cell"

public class LCYCoreDataCVC: UICollectionViewController, NSFetchedResultsControllerDelegate {
    
    public var frc:NSFetchedResultsController!

    //MARK: - FETCHING
    
    public func performFetch() throws {
        frc.managedObjectContext.performBlockAndWait { () -> Void in
                        
            do {
                try self.frc.performFetch()
            } catch {
                print("Failed to perform fetch")
            }

            self.collectionView?.reloadData()
        }
    }
   
    // MARK: UICollectionViewDataSource

    override public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        var numberOfSections: Int = 0
        if let sections = self.frc.sections {
            numberOfSections = sections.count
        }
        return numberOfSections
    }


    override public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
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
            
            self.collectionView?.insertSections(NSIndexSet(index: sectionIndex))
            break;
        case NSFetchedResultsChangeType.Delete:
            self.collectionView?.deleteSections(NSIndexSet(index: sectionIndex))
            break;
        default:
            break;
        }
    }
    
    public func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case NSFetchedResultsChangeType.Insert:
            if let newPath = newIndexPath {
                self.collectionView?.insertItemsAtIndexPaths([newPath])
            }
            break;
        case NSFetchedResultsChangeType.Delete:
            if let idxPath = indexPath {
                self.collectionView?.deleteItemsAtIndexPaths([idxPath])
            }
            break;
        case NSFetchedResultsChangeType.Update:
            if let newPath = newIndexPath {
                if let idxPath = indexPath {
                    self.collectionView?.deleteItemsAtIndexPaths([idxPath])
                    self.collectionView?.insertItemsAtIndexPaths([newPath])
                }
            } else {
                if let idxPath = indexPath {
                    self.collectionView?.reloadItemsAtIndexPaths([idxPath])
                }
            }
            break;
        case NSFetchedResultsChangeType.Move:
            if let newPath = newIndexPath {
                if let idxPath = indexPath {
                    self.collectionView?.deleteItemsAtIndexPaths([idxPath])
                    self.collectionView?.insertItemsAtIndexPaths([newPath])
                }
            }
            break;
        }
        
    }

}
