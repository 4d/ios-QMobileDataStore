//
//  DataStoreFieldInfo.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 14/03/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation

/// Information about a field.
public protocol DataStoreFieldInfo: NSSortDescriptorConvertible {
    /// The field name.
    var name: String {get}
    /// The localized name if any.
    var localizedName: String {get}
    /// The type.
    var type: DataStoreFieldType {get}
    /// If optional, value could be empty or nil
    var isOptional: Bool {get}
    /// Custom user information
    var userInfo: [AnyHashable: Any]? {get}
    /// The parent table.
    var table: DataStoreTableInfo {mutating get}
    /// Some predicate used to validate the value.
    var validationPredicates: [NSPredicate] { get }
}

//let knameTransformer = "nameTransformer"

extension DataStoreFieldInfo {
    /// The field is mandatory if the value must not be empty(ie. not optional)
    public var isMandatory: Bool {
        return !isOptional
    }

    /*public var nameTransformer: String? {
     return self.userInfo?[knameTransformer] as? String
     }*/
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
        assert(type.isSortable)
        return NSSortDescriptor(key: self.name, ascending: true)
    }
    public func sortDescriptor(ascending: Bool = true) -> NSSortDescriptor {
        assert(type.isSortable)
        return NSSortDescriptor(key: self.name, ascending: ascending)
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
