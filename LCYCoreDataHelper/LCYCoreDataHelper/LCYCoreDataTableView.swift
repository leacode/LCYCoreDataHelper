
//
//  LCYCoreDataTableView.swift
//  LCYCoreDataHelper
//
//  Created by LiChunyu on 16/1/24.
//  Copyright © 2016年 leacode. All rights reserved.
//

import CoreData
import UIKit

open class LCYCoreDataTableView: UITableView, NSFetchedResultsControllerDelegate {
    open var frc: NSFetchedResultsController<NSFetchRequestResult>!

    public override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: - FETCHING

    open func performFetch() {
        frc.managedObjectContext.performAndWait { () -> Void in
            do {
                try self.frc.performFetch()
            } catch {
                print("Failed to perform fetch")
            }

            self.reloadData()
        }
    }

    // MARK: - DATASOURCE: UITableView

    open override func numberOfRows(inSection section: Int) -> Int {
        var numberOfRow: Int = 0
        if let sections = self.frc.sections {
            numberOfRow = sections[section].numberOfObjects
        }
        return numberOfRow
    }

    open func numberOfSectionsInTableView() -> Int {
        var numberOfSections: Int = 0
        if let sections = self.frc.sections {
            numberOfSections = sections.count
        }
        return numberOfSections
    }

    open func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return frc.section(forSectionIndexTitle: title, at: index)
    }

    open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let name: String? = nil

        return name
    }

    open func sectionIndexTitlesForTableView(_ tableView: UITableView) -> [String]? {
        return frc.sectionIndexTitles
    }

    // MARK: - DELEGATE: NSFetchedResultsController

    open func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        beginUpdates()
    }

    open func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        endUpdates()
    }

    open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case NSFetchedResultsChangeType.insert:
            insertSections(IndexSet(integer: sectionIndex), with: UITableView.RowAnimation.fade)
            break
        case NSFetchedResultsChangeType.delete:
            deleteSections(IndexSet(integer: sectionIndex), with: UITableView.RowAnimation.fade)
            break
        default:
            break
        }
    }

    open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case NSFetchedResultsChangeType.insert:
            if let newPath = newIndexPath {
                insertRows(at: [newPath], with: UITableView.RowAnimation.automatic)
            }
            break
        case NSFetchedResultsChangeType.delete:
            if let idxPath = indexPath {
                deleteRows(at: [idxPath], with: UITableView.RowAnimation.automatic)
            }
            break
        case NSFetchedResultsChangeType.update:
            if let newPath = newIndexPath {
                if let idxPath = indexPath {
                    deleteRows(at: [idxPath], with: UITableView.RowAnimation.automatic)
                    insertRows(at: [newPath], with: UITableView.RowAnimation.automatic)
                }
            } else {
                if let idxPath = indexPath {
                    reloadRows(at: [idxPath], with: UITableView.RowAnimation.automatic)
                }
            }
            break
        case NSFetchedResultsChangeType.move:
            if let newPath = newIndexPath {
                if let idxPath = indexPath {
                    deleteRows(at: [idxPath], with: UITableView.RowAnimation.automatic)
                    insertRows(at: [newPath], with: UITableView.RowAnimation.automatic)
                }
            }
            break
        @unknown default:
            break
        }
    }
}
