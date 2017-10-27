//
//  DataStoreTable.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 24/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

public protocol DataStoreTableInfo {
    var name: String {get}
    var localizedName: String {get}
    var isAbstract: Bool {get}
    var fields: [DataStoreFieldInfo] {get}
    var fieldsByName: [String: DataStoreFieldInfo] { get }
    var relationships: [DataStoreRelationInfo] { get }
    var relationshipsByName: [String: DataStoreRelationInfo] { get }
    func relationships(for table: DataStoreTableInfo) -> [DataStoreRelationInfo]
    var userInfo: [AnyHashable: Any]? { get }
}

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

public protocol DataStoreFieldInfo {
    var name: String {get}
    var localizedName: String {get}
    var type: DataStoreFieldType {get}
    var isOptional: Bool {get}
    var userInfo: [AnyHashable: Any]? {get}
    var table: DataStoreTableInfo {mutating get}
    var validationPredicates: [NSPredicate] { get }
}

let kkeyMapping = "keyMapping"
let knameTransformer = "nameTransformer"

extension DataStoreFieldInfo {
    public var isMandatory: Bool {
        return !isOptional
    }

    public var mappedName: String? {
        return self.userInfo?[kkeyMapping] as? String
    }

    public var nameTransformer: String? {
        return self.userInfo?[kkeyMapping] as? String
    }
}

public protocol DataStoreRelationInfo {
    var name: String {get}

    var destinationTable: DataStoreTableInfo? { get }
    var inverseRelationship: DataStoreRelationInfo? { get }
    var maxCount: Int { get }
    var minCount: Int { get }
    var deleteRule: DeleteRule { get }
    var isToMany: Bool { get }
    var isOrdered: Bool { get }
    var isOptional: Bool {get}
    var userInfo: [AnyHashable: Any]? {get}

}
public enum DeleteRule: UInt {
    case noAction
    case nullify
    case cascade
    case deny
}
