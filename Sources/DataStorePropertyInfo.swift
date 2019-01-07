//
//  DataStorePropertyInfo.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 07/01/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation

/// Information about a property of table.
public protocol DataStorePropertyInfo {
    /// The field name.
    var name: String {get}

    /// Some additional info that could be added to the property.
    var userInfo: [AnyHashable: Any]? {get}

    /// The parent table.
    var table: DataStoreTableInfo {mutating get}

    /// If optional, value could be empty or nil
    var isOptional: Bool {get}
}
