//
//  MetaDataTests.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 16/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import XCTest
@testable import QMobileDataStore

class MetaDataTests: XCTestCase {

    lazy var dataStore: DataStore = {
        return DataStoreFactoryTest.dataStore
    }()
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
        assert(dataStore.delegate == nil) // launch setup of lazy var
        XCTAssertNotNil(Bundle.dataStoreModelName)

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
    func testMetaData<T, U: Equatable>(_ expectedValue:  [T: U]) {
        var metadata = dataStore.metadata
        let key = UUID().uuidString
        XCTAssertNil(metadata?[key])
        metadata?[key] = expectedValue
        XCTAssertNotNil(metadata?[key])
        
        if let value = metadata?[key] as? [T: U] {
            XCTAssertEqual(value, expectedValue)
        }
        
        metadata?[key] = nil
        XCTAssertNil(metadata?[key])
    }

    
}
