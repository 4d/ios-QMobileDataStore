//
//  QMobileCoreDataStoreTests.swift
//  QMobileCoreDataStoreTests
//
//  Created by Eric Marchand on 13/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import XCTest
@testable import QMobileDataStore

import Prephirences
import Result
import CoreData

import MomXML


class CoreDataStoreTests: XCTestCase {

    lazy var dataStore: DataStore = {
        return DataStoreFactoryTest.dataStore
    }()
    let timeout: TimeInterval = 15

    var onMerge: ((_ dataStore: DataStore, _ context: DataStoreContext, _ with: DataStoreContext) -> Void)? = nil

    var table: String {
        let expected = "Entity"
        if dataStore.tableInfo(for: expected) == nil { // if not in model return the first one
            return dataStore.tablesInfo.first?.name ?? expected
        } else {
            return expected
        }
    }
    let testqueue = DispatchQueue(label: "test.queue")

    let waitHandler: XCWaitCompletionHandler = { error in
        if let error = error {
            XCTFail("Failed to wait expectation: \(error)")
        }
    }
    
    let contextType: DataStoreContextType = .background

    override func setUp() {
        super.setUp()

        /*guard let dataStore = self.dataStore else {
            XCTFail("No data store to test")
            return
        }*/

        dataStore.delegate = self

        XCTAssertNotNil( dataStore.tableInfo(for: table))
        let expectation = self.expectation(description: #function)
        dataStore.load { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }

    override func tearDown() {
        let expectation = self.expectation(description: #function)

        dataStore.delegate = nil
        dataStore.drop { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                
                XCTFail("\(error)")
            }
        }
        self.waitForExpectations(timeout: timeout, handler: waitHandler)

        super.tearDown()
    }
    
    // MARK: test structure
    func testTablesInfo() {
        let tablesInfo = dataStore.tablesInfo

        XCTAssertFalse(tablesInfo.isEmpty)
        XCTAssertTrue(tablesInfo.map{$0.name}.contains(table))
        
        for tableInfo in tablesInfo {
            XCTAssertFalse(tableInfo.name.isEmpty)
            if !ProcessInfo.isSwiftRuntime {
                XCTAssertNotEqual(tableInfo.localizedName, tableInfo.name)
            }
        }
    }

    func testFieldForTable() {
        guard let tableInfo = dataStore.tableInfo(for: table) else {
            XCTFail("No table \(table) in table info")
            return
        }
        let fields = tableInfo.fields
        XCTAssertFalse(fields.isEmpty)
        XCTAssertEqual(fields.count, 11)


        if !DataStoreFactoryTest.inMemoryModel  {
            var hasLocalizedField = false
            for field in fields {
                XCTAssertFalse(field.name.isEmpty)
                XCTAssertFalse(field.type == .undefined)
                if field.name != field.localizedName {
                    hasLocalizedField = true
                }
            }
            XCTAssertTrue(hasLocalizedField, "One field must be localized, see strings file")
        }

        let relations = tableInfo.relationships
        for _ in relations {
        }
    }
    
    func testRelationshipTypeForTable() {
        guard let tableInfo = dataStore.tableInfo(for: table) else {
            XCTFail("No table \(table) in table info")
            return
        }

        let relationships = tableInfo.relationshipsByName
        XCTAssertFalse(relationships.isEmpty)
        XCTAssertEqual(relationships.count, 2)

        for relation in relationships {

            if (relation.key == "entity0relation1") {
                XCTAssertFalse(relation.value.isToMany)
            } else {
                XCTAssertTrue(relation.value.isToMany)
            }
        }
    }

    func testRelationshipDeleteRuleForTable() {
        guard let tableInfo = dataStore.tableInfo(for: table) else {
            XCTFail("No table \(table) in table info")
            return
        }

        let relationships = tableInfo.relationshipsByName
        XCTAssertFalse(relationships.isEmpty)
        XCTAssertEqual(relationships.count, 2)

        for relation in relationships {

            if (relation.key == "entity0relation1") {
                XCTAssertEqual(relation.value.deleteRule, .cascade)
            } else {
                XCTAssertEqual(relation.value.deleteRule, .nullify)
            }
        }
    }

    func testDeleteRuleBehavior() {
        guard !DataStoreFactoryTest.inMemoryModel else { return } // cannot cast with in memory model
        let expectation = self.expectation(description: #function)

        let _ = dataStore.perform(contextType) { context in

            let entity1TableName = "Entity1"
            
            guard let recordEntityTest = context.create(in: self.table) else {
                XCTFail("Cannot create entity from table \(self.table)")
                return
            }
           let recordEntity = recordEntityTest.store
    
            guard let recordEntity1 = context.create(in: entity1TableName)?.store else {
                XCTFail("Cannot create entity from \(entity1TableName)")
                return
            }

            recordEntity.setValue(recordEntity1, forKey: "entity0relation1")
          
            try? context.commit()

            XCTAssertNotNil(recordEntity.value(forKey: "entity0relation1"))
            XCTAssertTrue((try? context.has(in: self.table, matching : recordEntity.predicate)) ?? false, "\(recordEntity.objectID)")
            XCTAssertTrue((try? context.has(in: entity1TableName, matching : recordEntity1.predicate)) ?? false, "\(recordEntity1.objectID)")

            context.delete(record: Record(store: recordEntity1))
            try? context.commit()
            
            XCTAssertTrue((try? context.has(in: self.table, matching : recordEntity.predicate)) ?? false, "\(recordEntity.objectID)")
            XCTAssertFalse((try? context.has(in: entity1TableName, matching : recordEntity1.predicate)) ?? false, "\(recordEntity1.objectID)")
            XCTAssertNil(recordEntity.value(forKey: "entity0relation1"))

            expectation.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }

    // MARK: DataStore
    func testDataStoreSave() {
        let expectation = self.expectation(description: #function)

        dataStore.save { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }

        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }

    func testDataStoreSaveNotif() {
        let expectation = self.expectation(description: #function)
        let testQueue = OperationQueue()
        testQueue.underlyingQueue = testqueue
        let obs = dataStore.observe(.dataStoreSaved, queue: testQueue) { notif in
            expectation.fulfill()
        }

        dataStore.save { [unowned self] result in
            switch result {
            case .success:
                print("success ok. wait for event")
            case .failure(let error):
                XCTFail("\(error)")
            }
            self.dataStore.unobserve(obs)
        }
        
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }
    
    
    // MARK: NSManagedObjectContext
    func testGetAndCreateDefaultContext() {
        let _ = NSManagedObjectContext.default
    }
    // MARK: NSManagedObjectContext
    func testGetAndCreateBackgroundContext() {
        let _ = NSManagedObjectContext.newBackgroundContext()
    }
    
    // MARK: Entity
    func testEntityCreate() {
        let expectation = self.expectation(description: #function)
   
        let _ = dataStore.perform(contextType) { context in
      
            if let record = context.create(in: self.table) {
                if !DataStoreFactoryTest.inMemoryModel {
                    do {
                        try record.validateForInsert()
                    } catch {
                        XCTFail("Entity not valid to insert \(error) in data store")
                    }
                }
                let _ = record["attribute"]
                
                record["attribute"] = 10
                XCTAssertEqual(record["attribute"] as? Int, 10)
                
                
                XCTAssertTrue(try! context.has(in: self.table, matching : record.predicate))

                let getObject = try! context.get(in: self.table, matching : record.predicate)
                XCTAssertNotNil(getObject)
                XCTAssertFalse(getObject!.isEmpty)

                XCTAssertEqual(record.store.objectID, getObject!.first!.store.objectID)
                
                // unknown attribute will throw assert
                // let _ = record["attribute \(UUID().uuidString)"]
                
            } else {
                XCTFail("Cannot create entity")
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }
    
    func testEntityCreateFalseTable() {
        let expectation = self.expectation(description: #function)
        
        let _ = dataStore.perform(contextType) { context in
            let record = context.create(in: "\(self.table)\(UUID().uuidString)")
            XCTAssertNil(record)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }

    // test commented: onMerge is never called
    // before tearDown due to threading, so if the database is dropped, the merge could not be done
    func _testEntityCreateAndCheckViewContext() {
        let expectation = self.expectation(description: #function)

        let _ = dataStore.perform(contextType) { context in

            if let record = context.create(in: self.table) {
                do {
                    try record.validateForInsert()
                } catch {
                    XCTFail("Entity not valid to insert \(error) in data store")
                }
                let _ = record["attribute"]

                record["attribute"] = 10
                XCTAssertEqual(record["attribute"] as? Int, 10)

                XCTAssertTrue(try! context.has(in: self.table, matching : record.predicate))

                _ = self.dataStore.perform(.foreground, wait: true) { viewContext in
                    XCTAssertFalse(try! viewContext.has(in: self.table, matching : record.predicate), "Must not be yet in viewContext, commit needed")
                }

                self.onMerge = { _, _, _ in
                    self.onMerge = nil
                    _ = self.dataStore.perform(.foreground, wait: true) { viewContext in
                        XCTAssertTrue(try! viewContext.has(in: self.table, matching : record.predicate), "record must has been transfered to view context")
                        expectation.fulfill()
                    }
                }

                context.commit { result in
                    XCTAssertNotEqual(DataStoreContextType.foreground, self.contextType, "testing on view context, the following test is now useless")
                    // a merge will occur
                }

            } else {
                XCTFail("Cannot create entity")
            }
        }
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }
    
    
    func testEntityCreateMandatoryFieldTable() {
        guard !DataStoreFactoryTest.inMemoryModel else { return } // cannot cast with in memory model
        let expectation = self.expectation(description: #function)
        
        let _ = dataStore.perform(contextType) { context in
            
            if let record = context.create(in: "\(self.table)1") {
                
                do {
                    try record.validateForInsert()
                    
                    XCTFail("Must not be valid, a parameter is requested")
                    // dataStore.save will failed
                } catch {
                    print("Entity1 not valid to insert \(error) in data store. OK")
                }
                
                do {
                    try context.commit()
                    XCTFail("Expecting error when saving context with invalid object")
                } catch {
                    print("ok save connot be done ")
                    if let dataStoreError = error as? DataStoreError {
                        print(String(describing:  dataStoreError.errorDescription))
                        print(String(describing:  dataStoreError.failureReason))
                        print("\(error)")
                    }
                }
  
                record["attribute1"] = "454545"
                XCTAssertEqual(record["attribute1"] as? String, "454545")

                do {
                    try record.validateForInsert()
                } catch {
                    XCTFail("Entity not valid to insert \(error) in data store")
                }
                
                XCTAssertTrue(try! context.has(in: "\(self.table)1", matching : record.predicate))
                
                // unknown attribute will throw assert
                // let _ = record["attribute \(UUID().uuidString)"]
             
                do {
                    try context.commit()
                } catch {
                    XCTFail("Expecting error \(error)")
                }
                expectation.fulfill()
            } else {
                XCTFail("Cannot create entity")
            }
        }
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }

    func testEntityDelete() {
        let expectation = self.expectation(description: #function)
        
        let _ = dataStore.perform(contextType) { context in
            
            if let record = context.create(in: self.table) {
                
                XCTAssertTrue(try! context.has(in: self.table, matching : record.predicate))
                
                context.delete(records: [record])
                
                // check no more in context
                XCTAssertFalse(try! context.has(in: self.table, matching : record.predicate))
            } else {
                XCTFail("Cannot create entity")
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }

    func _testEntityUpdate() {
        let expectation = self.expectation(description: #function)
        
        let _ = dataStore.perform(contextType) { context in

            if let record = context.insert(in: self.table, values: ["attribute": 0]) {
                let predicate = record.predicate
                XCTAssertTrue(try! context.has(in: self.table, matching: predicate))
                XCTAssertTrue(context.has(record: record))
                
                var get = try! context.get(in: self.table, matching: predicate)?.first
                XCTAssertEqual(get, record)

                try? context.commit()
                let newValue = 11
                let result = try! context.update(in: self.table, matching: .true /*all?*/, values: ["attribute": newValue])
                XCTAssertTrue(result) // FIXME
                
                get = try! context.get(in: self.table, matching: predicate)?.first
                
                //XCTAssertEqual( get?["attribute"] as? Int, newValue)
                context.refresh(record, mergeChanges: true)
                get = try! context.get(in: self.table, matching: predicate)?.first
                
               XCTAssertEqual(get?["attribute"] as? Int, newValue)
            } else {
                XCTFail("Cannot create entity")
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }

    
    func testEntityDeleteUsingPredicate() {
        let expectation = self.expectation(description: #function)
        
        let _ = dataStore.perform(contextType) { context in
            
            guard let record = context.create(in: self.table) else {
                XCTFail("Cannot create entity")
                return
            }
            XCTAssertTrue((try? context.has(in: self.table, matching : record.predicate)) ?? false)

           /* context.commit { result in
                if case let.failure(error) = result {
                    XCTFail("failed to commit \(error)")
                }*/
                context.refreshAllRecords()
                XCTAssertTrue((try? context.has(in: self.table, matching : record.predicate)) ?? false, "no more in context after commit")

                context.refreshAllRecords()

                let result: Int  = (try? context.delete(in: self.table, matching: record.predicateForBatch)) ?? 0
                XCTAssertTrue(result>0, "no record deleted")

                context.refreshAllRecords()
                // check no more in context
                XCTAssertFalse(try! context.has(in: self.table, matching : record.predicate))

                expectation.fulfill()
           /* }*/

        }
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }

    func testEntityDeleteAll() {
        let expectation = self.expectation(description: #function)

        let _ = dataStore.perform(contextType) { context in

            guard let record = context.create(in: self.table) else {
                XCTFail("Cannot create entity")
                return
            }
            guard let record2 = context.create(in: self.table) else {
                XCTFail("Cannot create entity 2")
                return
            }
            XCTAssertTrue((try? context.has(in: self.table, matching : record.predicate)) ?? false, "\(record.store.objectID)")
            XCTAssertTrue((try? context.has(in: self.table, matching : record2.predicate)) ?? false, "\(record.store.objectID)")

            XCTAssertTrue(record.isInserted)
            XCTAssertFalse(record.isDeleted)

            context.commit { result in
                if case let.failure(error) = result {
                    XCTFail("failed to commit \(error)")
                }
                XCTAssertTrue((try? context.has(in: self.table, matching : record.predicate)) ?? false, "no more in context after commit")
                XCTAssertTrue((try? context.has(in: self.table, matching : record2.predicate)) ?? false, "no more in context after commit")

                XCTAssertTrue((try? context.count(in: self.table) > 1) ?? false, "no enought record")

                let result: Int  = (try? context.delete(in: self.table)) ?? 0
                XCTAssertTrue(result>0, "no record deleted")

                XCTAssertFalse(record.isInserted)
                XCTAssertTrue(record.isDeleted)

                // check no more in context
                XCTAssertFalse(try! context.has(in: self.table, matching : record.predicate), "\(record.store.objectID)")
                XCTAssertFalse(try! context.has(in: self.table, matching : record2.predicate), "\(record.store.objectID)")


                expectation.fulfill()
            }

        }
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }
    
    // MARK: Fetch
    func testFetch() {
        let expectation = self.expectation(description: #function)
        
        let fetchRequest = dataStore.fetchRequest(tableName: self.table, sortDescriptors: nil)
        
        let _ = dataStore.perform(contextType) { context in
            
            let count: Int = try! context.count(for: fetchRequest)
            if let _ = context.create(in: self.table) {
                XCTAssertEqual(try? context.count(for: fetchRequest), count + 1)
            } else {
                XCTFail("Cannot create entity")
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }
    
    func testFetchWithPredicate() {
        let expectation = self.expectation(description: #function)
        
        var fetchRequest = dataStore.fetchRequest(tableName: self.table, sortDescriptors: nil)
        
        let _ = dataStore.perform(contextType) { context in
            
            if let record = context.create(in: self.table) {
                
                fetchRequest.predicate = record.predicateForBatch
                
                let exist = fetchRequest.evaluate(record: record)
                
                XCTAssertTrue(exist)
                
                XCTAssertEqual(try? context.count(for: fetchRequest), 1)
                
                
            } else {
                XCTFail("Cannot create entity")
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }

    
    // MARK: FetchController
    func _testFetchController() {
        let expectation = self.expectation(description: #function)

        guard let tableInfo = dataStore.tableInfo(for: table), let fieldInfo = tableInfo.fields.first else {
            XCTAssertNil("Unable to get table info \(table) and first field info")
            return
        }
        let sortDescriptor: NSSortDescriptor = fieldInfo.sortDescriptor
        let controller = dataStore.fetchedResultsController(tableName: self.table, sortDescriptors: [sortDescriptor])
        XCTAssertEqual(controller.tableName, self.table)
        XCTAssertNil(controller.sectionNameKeyPath)
        
        try? controller.performFetch()

        let numberOfRecords = controller.numberOfRecords
        XCTAssertEqual(controller.isEmpty, numberOfRecords == 0)
        
        let records = controller.fetchedRecords
        XCTAssertNotNil(records)
        XCTAssertEqual(numberOfRecords, records?.count ?? 0)
        
        for record in records ?? [] {
            let indexPath = controller.indexPath(for: record)
            XCTAssertNotNil(indexPath)
            let r = controller.record(at: indexPath!)
            XCTAssertNotNil(r)
            
            XCTAssertTrue(controller.inBounds(indexPath: indexPath!))
        }

        let _ = dataStore.perform(contextType) { context in
            
            if let record = context.create(in: self.table) {
                try? context.commit()
 
                try? controller.performFetch()
                
                record["attribute"] = 10
                
                let numberOfRecords = controller.numberOfRecords
                XCTAssertEqual(controller.isEmpty, numberOfRecords == 0)
                
                let records = controller.fetchedRecords
                XCTAssertNotNil(records)
                XCTAssertEqual(numberOfRecords, records!.count)
                
                for record in records! {
                    let indexPath = controller.indexPath(for: record)
                    XCTAssertNotNil(indexPath)
                    let r = controller.record(at: indexPath!)
                    XCTAssertNotNil(r)
                    
                    XCTAssertTrue(controller.inBounds(indexPath: indexPath!))
                }

                let numberOfSections = controller.numberOfSections
                for section in 0..<numberOfSections {
                    let number = controller.numberOfRecords(in: section)
                    
                    XCTAssertTrue(number > 0) // because of save
                }
            } else {
                XCTFail("Cannot create entity to test fetch controller")
            }

            expectation.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }
}

extension CoreDataStoreTests: DataStoreDelegate {

    func dataStoreWillSave(_ dataStore: DataStore, context: DataStoreContext) {
        logger.debug("Data store will save: context \(context.type)")
        if !context.insertedRecords.isEmpty {
            logger.debug("insertedRecords: \(context.insertedRecords)")
        }
        if !context.updatedRecords.isEmpty {
            logger.debug("context.updatedRecords: \(context.updatedRecords)")
        }
        if !context.deletedRecords.isEmpty {
            logger.debug("deletedRecords: \(context.deletedRecords)")
        }
    }
    func dataStoreDidSave(_ dataStore: DataStore, context: DataStoreContext) {
        logger.debug("Data store did save: context \(context.type)")

    }
    func objectsDidChange(dataStore: DataStore, context: DataStoreContext) {

    }
    func dataStoreWillLoad(_ dataStore: DataStore) {

    }
    func dataStoreDidLoad(_ dataStore: DataStore) {

    }
    func dataStoreAlreadyLoaded(_ dataStore: DataStore) {

    }

    func dataStoreWillMerge(_ dataStore: DataStore, context: DataStoreContext, with: DataStoreContext) {

    }

    func dataStoreDidMerge(_ dataStore: DataStore, context: DataStoreContext, with: DataStoreContext) {
       onMerge?(dataStore, context, with)
    }
}
