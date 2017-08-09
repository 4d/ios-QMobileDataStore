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
        }
    }
    
    func testFieldForTable() {
        if let tableInfo = dataStore.tableInfo(for: table) {
            let fields = tableInfo.fields
            XCTAssertFalse(fields.isEmpty)
            XCTAssertTrue(fields.count == 10)
            
            for field in fields {
                XCTAssertFalse(field.name.isEmpty)
                XCTAssertFalse(field.type.isEmpty)
            }
        } else {
            XCTFail("No table \(table) in table info")
        }
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
   
        let _ = dataStore.perform(.background, { (context, save) in
      
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
        
        let _ = dataStore.perform(.background, { (context, save) in
            let record = context.create(in: "Entity \(UUID().uuidString)")
            XCTAssertNil(record)
            expectation.fulfill()
        })
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }
    
    func testEntityDelete() {
        let expectation = self.expectation(description: #function)
        
        let _ = dataStore.perform(.background, { (context, save) in
            
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

    func testEntityUpdate() {
        let expectation = self.expectation(description: #function)
        
        let _ = dataStore.perform(.background, { (context, save) in

            if let record = context.create(in: self.table) {
                XCTAssertTrue(try! context.has(in: self.table, matching: record.predicate))
                
               // try? save()
                let _ = try? context.update(in: self.table, matching: record.predicate, values: ["attribute": 11])

            } else {
                XCTFail("Cannot create entity")
            }
            expectation.fulfill()
        })
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }

    
    func testEntityDeleteUsingPredicate() {
        let expectation = self.expectation(description: #function)
        
        let _ = dataStore.perform(.background, { (context, save) in
            
            if let record = context.create(in: self.table) {
                
                XCTAssertTrue(try! context.has(in: self.table, matching : record.predicate))
                
                try? save()
                
                let result  = try! context.delete(in: self.table, matching: record.predicate)
                XCTAssertTrue(result, "not deleted")
                
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
        
        let _ = dataStore.perform(.background, { (context, save) in
            
            let count: Int = try! fetchRequest.count(context: context)
            if let _ = context.create(in: self.table) {

                XCTAssertEqual(try? fetchRequest.count(context: context), count + 1)
                
                
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
        
        let _ = dataStore.perform(.background, { (context, save) in
            
            if let record = context.create(in: self.table) {
                
                fetchRequest.predicate = NSPredicate(format: "objectID = %@", record.objectID) // not working with SELF...
                
                let exist = fetchRequest.evaluate(record: record)
                
                XCTAssertTrue(exist)
                
                XCTAssertEqual(try? fetchRequest.count(context: context), 1)
                
                
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

        let _ = dataStore.perform(.background, { (context, save) in
            
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
    
    
    func testMetaData() {
        testMetaData("expectedValue")
        testMetaData(true)
        testMetaData(["one", "two", ""])
        
        testMetaData(["one": "1", "two": "2", "": "empty"])
    }
    
    func testMetaData<T: Equatable>(_ expectedValue: T) {
        var metadata = dataStore.metadata
        let key = UUID().uuidString
        XCTAssertNil(metadata?[key])
        metadata?[key] = expectedValue
        XCTAssertNotNil(metadata?[key])
        let value = metadata?[key] as? T
        XCTAssertEqual(value, expectedValue)
        
        metadata?[key] = nil
        XCTAssertNil(metadata?[key])
    }
    func testMetaData<T: Equatable>(_ expectedValue: [T]) {
        var metadata = dataStore.metadata
        let key = UUID().uuidString
        XCTAssertNil(metadata?[key])
        metadata?[key] = expectedValue
        XCTAssertNotNil(metadata?[key])
        
        if let value = metadata?[key] as? [T] {
            XCTAssertEqual(value, expectedValue)
        }
        
        metadata?[key] = nil
        XCTAssertNil(metadata?[key])
    }
    func testMetaData<T : Hashable, U : Equatable>(_ expectedValue:  [T : U]) {
        var metadata = dataStore.metadata
        let key = UUID().uuidString
        XCTAssertNil(metadata?[key])
        metadata?[key] = expectedValue
        XCTAssertNotNil(metadata?[key])
        
        if let value = metadata?[key] as? [T : U] {
            XCTAssertEqual(value, expectedValue)
        }
        
        metadata?[key] = nil
        XCTAssertNil(metadata?[key])
    }
    
    
    

}
