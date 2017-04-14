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

class CoreDataStoreTests: XCTestCase {
    
    let bundle = Bundle(for: CoreDataStoreTests.self)
    var dataStore: CoreDataStore!
    let timeout: TimeInterval = 50

    let waitHandler: XCWaitCompletionHandler = { error in
        if let error = error {
            XCTFail("Failed to wait expectation: \(error)")
        }
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        let modelName = bundle[Bundle.dataStoreKey] as! String
        let model = CoreDataObjectModel.named(modelName , bundle)
        self.dataStore = CoreDataStore(model: model, storeType: .inMemory)
        self.dataStore.modelBundle = bundle

        guard let dataStore = self.dataStore else {
            XCTFail("No data store to test")
            return
        }
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

        self.dataStore?.drop { result in
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

    // MARK: test
    func testSave() {
        let expectation = self.expectation(description: #function)

        self.dataStore.save { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }

        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }
    
 

}
