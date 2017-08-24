//
//  CoreDataStoreTable.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 24/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import CoreData

struct CoreDataStoreTableInfo: DataStoreTableInfo {
    let entity: NSEntityDescription

    init(entity: NSEntityDescription) {
        self.entity = entity
    }

    init?(name: String, context: NSManagedObjectContext) {
        guard let des = NSEntityDescription.entity(forEntityName: name, in: context) else {
            return nil
        }
        self.entity = des
    }
    var userInfo: [AnyHashable : Any]? {
        return self.entity.userInfo
    }
    var fields: [DataStoreFieldInfo] {
        return entity.attributesByName.values.map { CoreDataStoreFieldInfo(attribute: $0) }
    }

    var fieldsByName: [String : DataStoreFieldInfo] {
        return Dictionary(entity.attributesByName.map {  ($0, CoreDataStoreFieldInfo(attribute: $1)) })
    }
    var isAbstract: Bool {
        return self.entity.isAbstract
    }
    var name: String {
        //swiftlint:disable:next force_cast
        return self.entity.name!
    }
}
extension Dictionary {
    init(_ pairs: [Element]) {
        self.init()
        for (k, v) in pairs {
            self[k] = v
        }
    }
}

struct CoreDataStoreFieldInfo: DataStoreFieldInfo {
    let attribute: NSAttributeDescription
    var name: String {
        return attribute.name
    }
    var userInfo: [AnyHashable : Any]? {
        return self.attribute.userInfo
    }

    var type: DataStoreFieldType {
        return self.attribute.attributeType.coreData
    }

    var isOptional: Bool {
        return self.attribute.isOptional
    }

    var table: DataStoreTableInfo {
        return CoreDataStoreTableInfo(entity: self.attribute.entity)
    }

    var validationPredicates: [NSPredicate] {
        return self.attribute.validationPredicates
    }
}

extension NSAttributeType {
    var coreData: String {
        switch self {
        case .binaryDataAttributeType:
            return "Binary"
        case .booleanAttributeType:
            return "Boolean"
        case .dateAttributeType:
            return "Date"
        case .decimalAttributeType:
            return "Decimal"
        case .doubleAttributeType:
            return "Double"
        case .floatAttributeType:
            return "Float"
        case .integer16AttributeType:
            return "Integer 16"
        case .integer32AttributeType:
            return "Integer 32"
        case .integer64AttributeType:
            return "Integer 64"
        case .stringAttributeType:
            return "String"
        case .transformableAttributeType:
            return "Transformable"
        case .objectIDAttributeType:
            return "Object ID"
        case .undefinedAttributeType:
            return ""
        }
    }
}
