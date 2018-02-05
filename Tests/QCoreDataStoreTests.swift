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

class CoreDataStoreTests: XCTestCase {
    
    let bundle = Bundle(for: CoreDataStoreTests.self)
  
    let timeout: TimeInterval = 10
    
    let table = "Entity"

    let waitHandler: XCWaitCompletionHandler = { error in
        if let error = error {
            XCTFail("Failed to wait expectation: \(error)")
        }
    }
    
    let contextType: DataStoreContextType = .background

    override func setUp() {
        super.setUp()
   
        //let modelName = bundle[Bundle.dataStoreKey] as! String
        //let model = CoreDataObjectModel.named(modelName , bundle)
        Bundle.dataStore = bundle
        
        
        /*self.dataStore = CoreDataStore(model: model, storeType: .inMemory) // memory do not allow batch update and delete
        self.dataStore.modelBundle = bundle
        CoreDataStore.default = self.dataStore*/
        
        XCTAssertNotNil(Bundle.dataStoreModelName)

        /*guard let dataStore = self.dataStore else {
            XCTFail("No data store to test")
            return
        }*/
        print("\(dataStore)")

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
            XCTAssertNotEqual(tableInfo.localizedName, tableInfo.name)
        }
    }

    func testFieldForTable() {
        var hasLocalizedField = false
        if let tableInfo = dataStore.tableInfo(for: table) {
            let fields = tableInfo.fields
            XCTAssertFalse(fields.isEmpty)
            XCTAssertEqual(fields.count, 11)
            
            for field in fields {
                XCTAssertFalse(field.name.isEmpty)
                XCTAssertFalse(field.type == .undefined)
                if field.name != field.localizedName {
                    hasLocalizedField = true
                }
            }
        } else {
            XCTFail("No table \(table) in table info")
        }
        XCTAssertTrue(hasLocalizedField, "One field must be localized, see strings file")
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
        testQueue.underlyingQueue = DispatchQueue(label: "test.queue")
        let obs = dataStore.observe(.dataStoreSaved, queue: testQueue) { notif in
            expectation.fulfill()
        }

        dataStore.save { result in
            switch result {
            case .success:
                print("success ok. wait for event")
            case .failure(let error):
                XCTFail("\(error)")
            }
            dataStore.unobserve(obs)
        }
        
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }
    
    
    // MARK: NSManagedObjectContext
    func testGetAndCreateContext() {
        let _ = NSManagedObjectContext.default
        let _ = NSManagedObjectContext.newBackgroundContext()
    }
    
    
    // MARK: Entity
    func testEntityCreate() {
        let expectation = self.expectation(description: #function)
   
        let _ = dataStore.perform(contextType, { (context, save) in
      
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
                
                // unknown attribute will throw assert
                // let _ = record["attribute \(UUID().uuidString)"]
                
            } else {
                XCTFail("Cannot create entity")
            }
            expectation.fulfill()
        })
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }
    
    func testEntityCreateFalseTable() {
        let expectation = self.expectation(description: #function)
        
        let _ = dataStore.perform(contextType, { (context, save) in
            let record = context.create(in: "\(self.table)\(UUID().uuidString)")
            XCTAssertNil(record)
            expectation.fulfill()
        })
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }
    
    
    func testEntityCreateMandatoryFieldTable() {
        let expectation = self.expectation(description: #function)
        
        let _ = dataStore.perform(contextType, { (context, save) in
            
            if let record = context.create(in: "\(self.table)1") {
                
                do {
                    try record.validateForInsert()
                    
                    XCTFail("Must not be valid, a parameter is requested")
                    // dataStore.save will failed
                } catch {
                    print("Entity1 not valid to insert \(error) in data store. OK")
                }
                
                do {
                    try save()
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
                    try save()
                } catch {
                    XCTFail("Expecting error \(error)")
                }
                expectation.fulfill()
            } else {
                XCTFail("Cannot create entity")
            }
        })
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }
    
    
    

    
    func testEntityDelete() {
        let expectation = self.expectation(description: #function)
        
        let _ = dataStore.perform(contextType, { (context, save) in
            
            if let record = context.create(in: self.table) {
                
                XCTAssertTrue(try! context.has(in: self.table, matching : record.predicate))
                
                context.delete(records: [record])
                
                // check no more in context
                XCTAssertFalse(try! context.has(in: self.table, matching : record.predicate))
            } else {
                XCTFail("Cannot create entity")
            }
            expectation.fulfill()
        })
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }

    func _testEntityUpdate() {
        let expectation = self.expectation(description: #function)
        
        let _ = dataStore.perform(contextType, { (context, save) in

            if let record = context.insert(in: self.table, values: ["attribute": 0]) {
                let predicate = record.predicate
                XCTAssertTrue(try! context.has(in: self.table, matching: predicate))
                XCTAssertTrue(context.has(record: record))
                
                var get = try! context.get(in: self.table, matching: predicate)?.first
                XCTAssertEqual(get, record)
                
                try? save()
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
        })
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }

    
    func testEntityDeleteUsingPredicate() {
        let expectation = self.expectation(description: #function)
        
        let _ = dataStore.perform(contextType, { (context, save) in
            
            if let record = context.create(in: self.table) {
                
                XCTAssertTrue(try! context.has(in: self.table, matching : record.predicate))
                
                try? save()
                
                let result  = try! context.delete(in: self.table, matching: record.predicate)
                XCTAssertTrue(result>0, "not deleted")
                
                // check no more in context
                XCTAssertFalse(try! context.has(in: self.table, matching : record.predicate))
            } else {
                XCTFail("Cannot create entity")
            }
            expectation.fulfill()
        })
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }
    
    // MARK: Fetch
    func testFetch() {
        let expectation = self.expectation(description: #function)
        
        let fetchRequest = dataStore.fetchRequest(tableName: self.table)
        
        let _ = dataStore.perform(contextType, { (context, save) in
            
            let count: Int = try! context.count(for: fetchRequest)
            if let _ = context.create(in: self.table) {

                XCTAssertEqual(try? context.count(for: fetchRequest), count + 1)
                
                
            } else {
                XCTFail("Cannot create entity")
            }
            expectation.fulfill()
        })
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }
    
    func testFetchWithPredicate() {
        let expectation = self.expectation(description: #function)
        
        var fetchRequest = dataStore.fetchRequest(tableName: self.table)
        
        let _ = dataStore.perform(contextType, { (context, save) in
            
            if let record = context.create(in: self.table) {
                
                fetchRequest.predicate = record.predicateForBatch
                
                let exist = fetchRequest.evaluate(record: record)
                
                XCTAssertTrue(exist)
                
                XCTAssertEqual(try? context.count(for: fetchRequest), 1)
                
                
            } else {
                XCTFail("Cannot create entity")
            }
            expectation.fulfill()
        })
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }

    
    // MARK: FetchController
    func testFetchController() {
        let expectation = self.expectation(description: #function)
        
        let controller = dataStore.fetchedResultsController(tableName: self.table)
        XCTAssertEqual(controller.tableName, self.table)
        XCTAssertNil(controller.sectionNameKeyPath)
        
        try? controller.performFetch()

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

        let _ = dataStore.perform(contextType, { (context, save) in
            
            if let record = context.create(in: self.table) {
                try? save()
 
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
        })
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }

}
