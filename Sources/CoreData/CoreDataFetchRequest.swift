//
//  CoreDataFetchRequest.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 14/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import CoreData
import Result

class CoreDataFetchRequest: FetchRequest {

    let fetchRequest: NSFetchRequest<RecordBase>
    init(_ fetchRequest: NSFetchRequest<RecordBase>) {
        self.fetchRequest = fetchRequest
    }
    init(_ fetchRequest: FetchRequest) {
        if let coredataRequest = fetchRequest as? CoreDataFetchRequest {
            self.fetchRequest = coredataRequest.fetchRequest // XXX could make a factory instead of init to not recreate the object
        } else {
            self.fetchRequest = CoreDataFetchRequest.from(request: fetchRequest)
        }
    }
    static func from<ResultType: NSFetchRequestResult>(request: FetchRequest) -> NSFetchRequest<ResultType> {
        let nsRequest = NSFetchRequest<ResultType>(entityName: request.tableName)

        nsRequest.predicate = request.predicate
        nsRequest.sortDescriptors = request.sortDescriptors
        nsRequest.fetchLimit = request.fetchLimit
        return nsRequest
    }

    public var tableName: String {
        return fetchRequest.entityName ?? ""
    }

    public var predicate: NSPredicate? {
        get {
            return fetchRequest.predicate
        }
        set {
            fetchRequest.predicate = newValue
        }
    }

    public var sortDescriptors: [NSSortDescriptor]? {
        get {
            return fetchRequest.sortDescriptors
        }
        set {
            fetchRequest.sortDescriptors = newValue
        }
    }

    public var fetchLimit: Int {   get {
        return fetchRequest.fetchLimit
        }
        set {
            fetchRequest.fetchLimit = newValue
        }
    }

}

enum RecordChange {
    case update(Int, Record)
    case delete(Int, Record)
    case insert(Int, Record)
}

internal class CoreDataFetchedResultsController: NSObject, FetchedResultsController {

    weak var delegate: FetchedResultsControllerDelegate?

    let fetchedResultsController: NSFetchedResultsController<RecordBase>
    let coreDataStore: CoreDataStore

    fileprivate var batchChanges: [RecordChange] = []

    init(dataStore: CoreDataStore, sectionNameKeyPath: String?, context: DataStoreContext? = nil, fetchRequest: NSFetchRequest<RecordBase>) {
        coreDataStore = dataStore

        let context = context as? NSManagedObjectContext ?? dataStore.viewContext
        self.fetchedResultsController = NSFetchedResultsController<RecordBase>(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: sectionNameKeyPath, cacheName: nil)

        super.init()

        self.fetchedResultsController.delegate = self
    }

    deinit {
        self.fetchedResultsController.delegate = nil
    }

    var fetchRequest: FetchRequest {
        return CoreDataFetchRequest(self.fetchedResultsController.fetchRequest)
    }

    var dataStore: DataStore {
        return coreDataStore
    }
    var context: DataStoreContext {
        return fetchedResultsController.managedObjectContext
    }
    func performFetch() throws {
        try self.fetchedResultsController.performFetch()
    }

    func fetch(keyPath: String, ascending: Bool) -> [Any] {
        var result = [Any]()
        // swiftlint:disable:next force_cast
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: tableName)
        request.resultType = .dictionaryResultType
        request.returnsDistinctResults = true
        request.propertiesToFetch = [keyPath]
        request.predicate = self.fetchedResultsController.fetchRequest.predicate
        request.sortDescriptors = [NSSortDescriptor(key: keyPath, ascending: ascending)]

        let context = self.fetchedResultsController.managedObjectContext

        if let objects = try? context.fetch(request) as? [NSDictionary] {
            for object in objects ?? [] {
                result.append(contentsOf: object.allValues)
            }
        }
        return result
    }

    var numberOfRecords: Int {
        let sections = self.fetchedResultsController.sections ?? [NSFetchedResultsSectionInfo]()
        if sections.isEmpty {
            return 0
        } else {
            var total = 0
            for section in sections {
                total += section.numberOfObjects
            }
            return total
        }
    }

    func record(at indexPath: IndexPath) -> Record? {
        if inBounds(indexPath: indexPath) {
            let store = self.fetchedResultsController.object(at: indexPath)
            return Record(store: store)
        }
        return nil
    }

    func indexPath(for record: Record) -> IndexPath? {
        return self.fetchedResultsController.indexPath(forObject: record.store)
    }

    var isEmpty: Bool {
        let sections = self.fetchedResultsController.sections ?? [NSFetchedResultsSectionInfo]()
        if sections.isEmpty {
            return true
        } else {
            for section in sections where section.numberOfObjects > 0 {
                return false
            }
        }
        return true
    }

    func inBounds(indexPath: IndexPath) -> Bool {
        return self.fetchedResultsController.sections?.count ?? 0 > indexPath.section &&
            self.fetchedResultsController.sections?[indexPath.section].numberOfObjects ?? 0 > indexPath.row
    }

    var numberOfSections: Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    func numberOfRecords(in section: FetchedResultsController.SectionIndex) -> Int {
        assert(section >= 0)
        return self.fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    var sectionNameKeyPath: String? {
        return self.fetchedResultsController.sectionNameKeyPath
    }

    open var sectionNames: [String]? {
        guard let sections = fetchedResultsController.sections else {
            return nil
        }
        return sections.map { $0.name }
    }

    func sectionName(_ section: FetchedResultsController.SectionIndex) -> String? {
        assert(section >= 0)
        return self.fetchedResultsController.sections?[section].name ?? nil
    }

    func record(in section: FetchedResultsController.SectionIndex) -> [Record]? {
        assert(section >= 0)
        guard let section = fetchedResultsController.sections?[section],
            let objects = section.objects as? [RecordBase] else {
            return nil
        }
        return objects.map { Record(store: $0) }
    }

    // /!\ time consuming
    var fetchedRecords: [Record]? {
        return self.fetchedResultsController.fetchedObjects?.map { Record(store: $0) }
    }

}

extension NSFetchedResultsChangeType {

    var mappedType: FetchedResultsChangeType {
        switch self {
        case .insert:
            return .insert
        case .update:
            return .update
        case .delete:
            return .delete
        case .move:
            return .move
        }
    }
}

extension CoreDataFetchedResultsController: NSFetchedResultsControllerDelegate {

    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let record = anObject as? RecordBase else {
            logger.warning("Wrong object type presented in data: \(anObject)")
            return
        }
        self.delegate?.controller(self, didChangeRecord: Record(store: record), at: indexPath, for: type.mappedType, newIndexPath: newIndexPath)
    }

    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        self.delegate?.controllerDidChangeSection(self, at: sectionIndex, for: type.mappedType)
    }

    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.delegate?.controllerWillChangeContent(self)
    }

    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.delegate?.controllerDidChangeContent(self)
    }

    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, sectionIndexTitleForSectionName sectionName: String) -> String? {
        return self.delegate?.controller(self, sectionIndexTitleForSectionName: sectionName)
    }

}

// MARK: FetchRequest in CoreDataStore

extension CoreDataStore {

    public func fetchRequest(tableName: String, sortDescriptors: [NSSortDescriptor]?) -> FetchRequest {
        let fetchRequest = NSFetchRequest<RecordBase>(entityName: tableName)
        fetchRequest.sortDescriptors = sortDescriptors

        return CoreDataFetchRequest(fetchRequest)
    }

    func fetchedResultsController(fetchRequest: FetchRequest, sectionNameKeyPath: String?, context: DataStoreContext? = nil) -> FetchedResultsController {

        // CLEAN Tricky way to add a sort descriptor... maybe add attribute name as attribute or flag in core data model

        let request = CoreDataFetchRequest(fetchRequest).fetchRequest
        if request.sortDescriptors == nil {
            if let sectionNameKeyPath = sectionNameKeyPath, sectionNameKeyPath != "" {
                request.sortDescriptors = [NSSortDescriptor(key: sectionNameKeyPath, ascending: true)]
            } else {
                if let entityDescription = NSEntityDescription.entity(forEntityName: fetchRequest.tableName, in: self.viewContext),
                    let key = entityDescription.attributesByName.first?.key {
                    request.sortDescriptors = [NSSortDescriptor(key: key, ascending: true)]
                } else {
                    fatalError("Table \(fetchRequest.tableName) has no fields and could not be displayed")
                }
            }
        }

        return CoreDataFetchedResultsController(dataStore: self, sectionNameKeyPath: sectionNameKeyPath, context: context, fetchRequest: request)
    }

}

extension NSManagedObjectContext {
    
    public func fetchRequest(tableName: String, sortDescriptors: [NSSortDescriptor]? = nil) -> FetchRequest {
        let fetchRequest = NSFetchRequest<RecordBase>(entityName: tableName)
        fetchRequest.sortDescriptors = sortDescriptors
        
        return CoreDataFetchRequest(fetchRequest)
    }
    
}

