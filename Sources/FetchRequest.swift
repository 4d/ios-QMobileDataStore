//
//  FetchRequest.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 14/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

/// A fetch request associated to a table name and created by the data store.
public protocol FetchRequest {

    /// The table name associated to this request
    var tableName: String { get }

    // MARK: parameters
    /// The predicate of the fetch request.
    var predicate: NSPredicate? { get set }
    ///The sort descriptors of the fetch request.
    var sortDescriptors: [NSSortDescriptor]? { get set }
    /// The fetch limit of the fetch request
    var fetchLimit: Int { get set }

    var fieldsToFetch: [String]? { get set }
    var relationshipsToFetch: [String]? { get set }

}

extension FetchRequest {

    /// Should this record be in our fetch results?
    /// Usefull awnser if there is some change on record.
    ///
    /// - parameters record: the record to evaluate.
    ///
    /// - returns: true if the fetch would include this record
    func evaluate(record: Record) -> Bool {
        if let predicate = self.predicate {
            return predicate.evaluate(with: record)
        }
        return true
    }

    // CLEAN Use NSPredicateConvertible and NSSortDescriptorConvertible
}

// MARK: Controller associated to a FetchRequest

/// A `FetchedResultsController` allow to observe `fetchRequest` change using a delegate and  to get some information about the `fetchRequest`
public protocol FetchedResultsController {

    var fetchRequest: FetchRequest { get }

    var delegate: FetchedResultsControllerDelegate? { get set }

    var dataStore: DataStore { get }

    var context: DataStoreContext { get }

    func performFetch() throws

    func fetch(keyPath: String, ascending: Bool) -> [Any]

    // MARK: Records
    var numberOfRecords: Int { get }
    var isEmpty: Bool { get }

    var fetchedRecords: [Record]? { get }
    func record(at: IndexPath) -> Record?
    func indexPath(for record: Record) -> IndexPath?

    func inBounds(indexPath: IndexPath) -> Bool

    // MARK: Section
    typealias SectionIndex = Int
    var numberOfSections: Int { get }
    var sectionNameKeyPath: String? { get }
    func numberOfRecords(in section: SectionIndex) -> Int
    func sectionName(_ section: SectionIndex) -> String?
    var sectionNames: [String]? { get }
    func section(forSectionIndexTitle title: String, at index: Int) -> Int
    func record(in section: FetchedResultsController.SectionIndex) -> [Record]?

}

extension FetchedResultsController {

    /// The table name associated to this controller
    public var tableName: String {
        return self.fetchRequest.tableName
    }

    /// Create a new fetch request on same table.
    public func newFetchRequest() -> FetchRequest {
        return self.dataStore.fetchRequest(tableName: tableName, sortDescriptors: self.fetchRequest.sortDescriptors)
    }

}

/// A delegate for `FetchedResultsController`, which receive information on controller modification
public protocol FetchedResultsControllerDelegate: class {
    /// content
    func controllerWillChangeContent(_ controller: FetchedResultsController)
    func controller(_ controller: FetchedResultsController, didChangeRecord aRecord: Record, at indexPath: IndexPath?, for type: FetchedResultsChangeType, newIndexPath: IndexPath?)
    func controllerDidChangeContent(_ controller: FetchedResultsController)

    /// section
    func controllerDidChangeSection(_ controller: FetchedResultsController, at sectionIndex: FetchedResultsController.SectionIndex, for type: FetchedResultsChangeType)
    func controller(_ controller: FetchedResultsController, sectionIndexTitleForSectionName sectionName: String) -> String?

}

/// Change type that occurs in fetched results controller
public enum FetchedResultsChangeType {
    case insert
    case delete
    case move
    case update
}
