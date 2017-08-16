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
    let bundle = Bundle(for: ContextTypeTests.self)
    
    let waitHandler: XCWaitCompletionHandler = { error in
        if let error = error {
            XCTFail("Failed to wait expectation: \(error)")
        }
    }
    
    override func setUp() {
        super.setUp()
        Bundle.dataStore = bundle
    
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
        
        let result = dataStore.perform(.background, { (context, save) in
            
            XCTAssertEqual(context.type, .background)
            XCTAssertNil(context.parentContext) // Not really a test, background has no parent until we decide change it, like at foreground context has parent
            
            expectation.fulfill()
        })
        if result {
            self.waitForExpectations(timeout: timeout, handler: waitHandler)
        } else {
            XCTFail("Failed to perform action on data store")
        }
    }
    
    func testForegroundIsForeground() {
        let expectation = self.expectation(description: #function)
        
        let result = dataStore.perform(.foreground, { (context, save) in
            
            XCTAssertEqual(context.type, .foreground)
            
            expectation.fulfill()
        })
        if result {
            self.waitForExpectations(timeout: timeout, handler: waitHandler)
        } else {
            XCTFail("Failed to perform action on data store")
        }
    }
    
    func testBackgroundIsBackgroundSync() {
        let expectation = self.expectation(description: #function)
        
        let result = dataStore.perform(.background, wait: true, { (context, save) in
            
            XCTAssertEqual(context.type, .background)
            
            expectation.fulfill()
        })
        if result {
            self.waitForExpectations(timeout: timeout, handler: waitHandler)
        } else {
            XCTFail("Failed to perform action on data store")
        }
    }
    
    func testForegroundIsForegroundSync() {
        let expectation = self.expectation(description: #function)
        
        let result = dataStore.perform(.foreground, wait: true, { (context, save) in
            
            XCTAssertEqual(context.type, .foreground)
            
            expectation.fulfill()
        })
        if result {
            self.waitForExpectations(timeout: timeout, handler: waitHandler)
        } else {
            XCTFail("Failed to perform action on data store")
        }
    }
}
