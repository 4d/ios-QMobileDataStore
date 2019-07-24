//
//  ContextTypeTests.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 16/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import XCTest
@testable import QMobileDataStore

class ContextTypeTests: XCTestCase {
    
    let timeout: TimeInterval = 10
    lazy var dataStore: DataStore = {
        return DataStoreFactoryTest.dataStore
    }()
    
    let waitHandler: XCWaitCompletionHandler = { error in
        if let error = error {
            XCTFail("Failed to wait expectation: \(error)")
        }
    }
    
    override func setUp() {
        super.setUp()
    
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
    
    func testBackgroundIsBackground() {
        let expectation = self.expectation(description: #function)
        
        let result = dataStore.perform(.background) { context in
            
            XCTAssertEqual(context.type, .background)
            //if dataStore.automaticMerge {
                XCTAssertNotNil(context.parentContext) // in automaticMerge, a parent needed
           // }

            expectation.fulfill()
        }
        if result {
            self.waitForExpectations(timeout: timeout, handler: waitHandler)
        } else {
            XCTFail("Failed to perform action on data store")
        }
    }
    
    func testForegroundIsForeground() {
        let expectation = self.expectation(description: #function)
        
        let result = dataStore.perform(.foreground) { context in
            
            XCTAssertEqual(context.type, .foreground)
            
            expectation.fulfill()
        }
        if result {
            self.waitForExpectations(timeout: timeout, handler: waitHandler)
        } else {
            XCTFail("Failed to perform action on data store")
        }
    }
    
    func testBackgroundIsBackgroundSync() {
        let expectation = self.expectation(description: #function)
        
        let result = dataStore.perform(.background, wait: true) { context in
            
            XCTAssertEqual(context.type, .background)
            
            expectation.fulfill()
        }
        if result {
            self.waitForExpectations(timeout: timeout, handler: waitHandler)
        } else {
            XCTFail("Failed to perform action on data store")
        }
    }
    
    func testForegroundIsForegroundSync() {
        let expectation = self.expectation(description: #function)
        
        let result = dataStore.perform(.foreground, wait: true) { context in
            
            XCTAssertEqual(context.type, .foreground)
            
            expectation.fulfill()
        }
        if result {
            self.waitForExpectations(timeout: timeout, handler: waitHandler)
        } else {
            XCTFail("Failed to perform action on data store")
        }
    }
}
