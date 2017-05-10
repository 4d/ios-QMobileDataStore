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

    var predicate: NSPredicate? { get }

}

extension NSPredicate: NSPredicateConvertible {

    public var predicate: NSPredicate? {
        return self
    }
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

public func && (left: NSPredicate, right: NSPredicate) -> NSPredicate {
    return [left] && [right]
}

public func && (left: [NSPredicate], right: [NSPredicate]) -> NSPredicate {
    let predicates: [NSPredicate] = left + right
    return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
}
public func || (left: NSPredicate, right: NSPredicate) -> NSPredicate {
    return [left] || [right]
}

public func || (left: [NSPredicate], right: [NSPredicate]) -> NSPredicate {
    let predicates: [NSPredicate] = left + right
    return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
}
prefix public func ! (left: NSPredicate) -> NSPredicate {
    return NSCompoundPredicate(type: .not, subpredicates: [left])
}
