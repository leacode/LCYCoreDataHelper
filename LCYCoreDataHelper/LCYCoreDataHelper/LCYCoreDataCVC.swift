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

open class LCYCoreDataCVC: UICollectionViewController, NSFetchedResultsControllerDelegate {
    
    open var frc:NSFetchedResultsController<NSFetchRequestResult>!
    
    //MARK: - FETCHING
    
    open func performFetch() throws {
        frc.managedObjectContext.performAndWait { () -> Void in
                        
            do {
                try self.frc.performFetch()
            } catch {
                print("Failed to perform fetch")
            }

            self.collectionView?.reloadData()
        }
    }
   
    // MARK: UICollectionViewDataSource

    override open func numberOfSections(in collectionView: UICollectionView) -> Int {
        var numberOfSections: Int = 0
        if let sections = self.frc.sections {
            numberOfSections = sections.count
        }
        return numberOfSections
    }


    override open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var numberOfRow: Int = 0
        if let sections = self.frc.sections {
            numberOfRow = sections[section].numberOfObjects
        }
        return numberOfRow
    }
    

    //MARK: - DELEGATE: NSFetchedResultsController
    
    
    
    open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case NSFetchedResultsChangeType.insert:
            
            self.collectionView?.insertSections(IndexSet(integer: sectionIndex))
            break;
        case NSFetchedResultsChangeType.delete:
            self.collectionView?.deleteSections(IndexSet(integer: sectionIndex))
            break;
        default:
            break;
        }
    }
    
    
    
    open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case NSFetchedResultsChangeType.insert:
            if let newPath = newIndexPath {
                self.collectionView?.insertItems(at: [newPath])
            }
            break;
        case NSFetchedResultsChangeType.delete:
            if let idxPath = indexPath {
                self.collectionView?.deleteItems(at: [idxPath])
            }
            break;
        case NSFetchedResultsChangeType.update:
            if let newPath = newIndexPath {
                if let idxPath = indexPath {
                    self.collectionView?.deleteItems(at: [idxPath])
                    self.collectionView?.insertItems(at: [newPath])
                }
            } else {
                if let idxPath = indexPath {
                    self.collectionView?.reloadItems(at: [idxPath])
                }
            }
            break;
        case NSFetchedResultsChangeType.move:
            if let newPath = newIndexPath {
                if let idxPath = indexPath {
                    self.collectionView?.deleteItems(at: [idxPath])
                    self.collectionView?.insertItems(at: [newPath])
                }
            }
            break;
        }
        
    }

}
