//
//  DataStoreFieldInfo.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 14/03/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation

/// Information about a field.
public protocol DataStoreFieldInfo: DataStorePropertyInfo, NSSortDescriptorConvertible {

    /// The localized name if any.
    var localizedName: String {get}
    /// The type.
    var type: DataStoreFieldType {get}

    /// The localized label if any.
    var label: String? {get}
    /// The localized short label if any.
    var shortLabel: String? {get}

    /// Some predicate used to validate the value.
    var validationPredicates: [NSPredicate] { get }
}

// let knameTransformer = "nameTransformer"

extension DataStoreFieldInfo {
    /// The field is mandatory if the value must not be empty(ie. not optional)
    public var isMandatory: Bool {
        return !isOptional
    }

    /*public var nameTransformer: String? {
     return self.userInfo?[knameTransformer] as? String
     }*/

    public var preferredLongLabel: String {
        return self.label ?? self.shortLabel ?? self.name
    }

    /// Return short label if any, then long label and finally name
    public var preferredShortLabel: String {
        return self.shortLabel ?? self.label ?? self.name
    }
}

/// List of available field type.
public enum DataStoreFieldType: String {
    case boolean
    case string
    case date
    case float
    case decimal
    case double
    case binary
    case integer16
    case integer32
    case integer64
    case transformable
    case undefined
    case objectID
}

extension DataStoreFieldType {

    public var isSortable: Bool {
        switch self {
        case .undefined, .binary, .transformable:
            return false
        default:
            return true
        }
    }
}

extension DataStoreFieldInfo {
    // MARK: NSSortDescriptorConvertible
    public var sortDescriptor: NSSortDescriptor {
        return sortDescriptor(ascending: true)
    }
    public func sortDescriptor(ascending: Bool = true) -> NSSortDescriptor {
        assert(type.isSortable)
        if case .string = self.type {
            return NSSortDescriptor(key: self.name, ascending: ascending, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        }
        return NSSortDescriptor(key: self.name, ascending: ascending)
    }
    public func sortDescriptor(name: String, ascending: Bool = true) -> NSSortDescriptor {
        assert(type.isSortable)
        if case .string = self.type {
            return NSSortDescriptor(key: name, ascending: ascending, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        }
        return NSSortDescriptor(key: name, ascending: ascending)
    }
}

extension DataStoreFieldInfo {
    // MARK: predicate to match this field with value
    func predicate(for value: Any,
                   modifier: NSComparisonPredicate.Modifier = .direct,
                   operator type: NSComparisonPredicate.Operator = .equalTo,
                   options: NSComparisonPredicate.Options = []) -> NSPredicate {
        return NSComparisonPredicate(
            leftExpression: NSExpression(forKeyPath: name),
            rightExpression: NSExpression(forConstantValue: name),
            modifier: modifier, type: type, options: options)
    }
}
