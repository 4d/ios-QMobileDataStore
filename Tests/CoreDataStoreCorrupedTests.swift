//
//  CoreDataStoreCorrupedTests.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 25/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

import XCTest
@testable import QMobileDataStore

import Prephirences
import Result
import CoreData

class CoreDataStoreCorrupedTests: XCTestCase {

    lazy var dataStore: DataStore = {
        Bundle.dataStore = Bundle(for: CoreDataStoreCorrupedTests.self)
        return DataStoreFactory.dataStore
    }()
    let timeout: TimeInterval = 10
    
    let table = "Entity"
    
    let waitHandler: XCWaitCompletionHandler = { error in
        if let error = error {
            XCTFail("Failed to wait expectation: \(error)")
        }
    }
    
    override func setUp() {
        super.setUp()
        assert(dataStore.delegate == nil) // launch setup of lazy var
        XCTAssertNotNil(Bundle.dataStoreModelName)
        print("\(dataStore)")
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

    func _testDataStoreCorrupted() {
        let expectation = self.expectation(description: #function)
        
        (dataStore as? CoreDataStore)?.corrupt()
        
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
    
    
}


extension CoreDataStore {
    func corrupt() {
        if let storeURL = self.storeURL {
            storeURL.corrupt()
            URL(fileURLWithPath:  "\(storeURL.absoluteString)-shm").corrupt()
            URL(fileURLWithPath:  "\(storeURL.absoluteString)-wal").corrupt()
        }
    }
}

extension URL {
    
    func corrupt() {
        if !self.isFileURL {
            return
        }
        do {
            //touch()
            let txt = UUID().uuidString
            try txt.write(toFile: self.absoluteString, atomically: true, encoding: .utf8)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func touch() {
        if !self.exists {
            createFile()
        }
    }
    
    func createFile()   {
        if !FileManager.default.createFile(atPath: self.absoluteString, contents: nil, attributes: nil) {
            
            XCTFail("cannot create \(self.absoluteString)")
        }
    }
    
    var exists: Bool {
        return FileManager.default.fileExists(atPath: self.absoluteString)
    }
}
