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
    var isAbstract: Bool {get}
    var fields: [DataStoreFieldInfo] {get}
    var fieldsByName: [String : DataStoreFieldInfo] { get }
    var userInfo: [AnyHashable : Any]? { get }
}
public typealias DataStoreFieldType = String
public protocol DataStoreFieldInfo {
    var name: String {get}
    var type: DataStoreFieldType {get}
    var isOptional: Bool {get}
    var userInfo: [AnyHashable : Any]? {get}
    var table: DataStoreTableInfo {get}
    var validationPredicates: [NSPredicate] { get }
}

extension DataStoreFieldInfo {
    public var isMandatory: Bool {
        return !isOptional
    }
}
