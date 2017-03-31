//
//  NSPredicateConvertible.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 14/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

/// An object that could be converted to a NSPredicate.
public protocol NSPredicateConvertible {

    init(predicate: NSPredicate)
    var predicate: NSPredicate? { get }

}

extension String: NSPredicateConvertible {

    public init(predicate: NSPredicate) {
        self = predicate.predicateFormat
    }

    public var predicate: NSPredicate? {
        if self.isEmpty {
            return nil
        }
        return NSPredicate(format: self)
    }

}

extension NSPredicate {

    @nonobjc public static let `true` = NSPredicate(value: true)
    @nonobjc public static let `false` = NSPredicate(value: false)

}
