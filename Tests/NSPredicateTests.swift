//
//  NSPredicateTests.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 13/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

import XCTest
@testable import QMobileDataStore

class NSPredicateTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    override func tearDown() {
        super.tearDown()
    }

    func testTrue() {
        XCTAssertTrue(NSPredicate.true.evaluate(with: nil))
        XCTAssertTrue(NSPredicate.true.evaluate(with: ""))
        XCTAssertTrue(NSPredicate.true.evaluate(with: []))
        XCTAssertTrue(NSPredicate.true.evaluate(with: "string"))
        XCTAssertTrue(NSPredicate.true.evaluate(with: [:]))
    }
    
    func testFalse() {
        XCTAssertFalse(NSPredicate.false.evaluate(with: nil))
        XCTAssertFalse(NSPredicate.false.evaluate(with: ""))
        XCTAssertFalse(NSPredicate.false.evaluate(with: []))
        XCTAssertFalse(NSPredicate.false.evaluate(with: "string"))
        XCTAssertFalse(NSPredicate.false.evaluate(with: [:]))
    }
    
    func testStringToPredicate() {
        XCTAssertNil("".predicate)
        XCTAssertNotNil("ww like ww".predicate)
        XCTAssertNotNil("TRUEPREDICATE".predicate)

        let string = String(predicate: NSPredicate.true)
        XCTAssertFalse(string.isEmpty)
    }
    
    func testPredicateToPredicate() {
        let predicate = NSPredicate.true
        XCTAssertEqual(predicate.predicate, predicate)
    }

    func testNSSortDescriptor() {
        let sortDescriptor = NSSortDescriptor(key: "test", ascending: true)
        XCTAssertEqual(sortDescriptor.sortDescriptor, sortDescriptor)
    }

}
    
