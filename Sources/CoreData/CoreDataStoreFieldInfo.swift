//
//  CoreDataStoreFieldInfo.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 14/03/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStoreFieldInfo: DataStoreFieldInfo {

    let attribute: NSAttributeDescription

    init( attribute: NSAttributeDescription) {
        self.attribute = attribute
    }

    var name: String {
        return self.attribute.name
    }
    var userInfo: [AnyHashable: Any]? {
        get {
            return self.attribute.userInfo
        }
        set {
            self.attribute.userInfo = newValue
        }
    }

    var type: DataStoreFieldType {
        return self.attribute.attributeType.dataStoreFieldType
    }

    var isOptional: Bool {
        return self.attribute.isOptional
    }

    lazy var table: DataStoreTableInfo = {
        return CoreDataStoreTableInfo(entity: self.attribute.entity)
    }()

    var validationPredicates: [NSPredicate] {
        return self.attribute.validationPredicates
    }

    var localizedName: String {
        let name = self.name
        // https://developer.apple.com/documentation/coredata/nsmanagedobjectmodel/1506846-localizationdictionary
        if let tablename = self.attribute.entity.name,
            let value = self.attribute.entity.managedObjectModel.localizationDictionary?["Property/\(name)/Entity/\(tablename)"] {
            return value
        }
        return name
    }
}

extension NSAttributeType {
    var dataStoreFieldType: DataStoreFieldType {
        switch self {
        case .binaryDataAttributeType:
            return .binary
        case .booleanAttributeType:
            return .boolean
        case .dateAttributeType:
            return .date
        case .decimalAttributeType:
            return .decimal
        case .doubleAttributeType:
            return .double
        case .floatAttributeType:
            return .float
        case .integer16AttributeType:
            return .integer16
        case .integer32AttributeType:
            return .integer32
        case .integer64AttributeType:
            return .integer64
        case .stringAttributeType:
            return .string
        case .transformableAttributeType:
            return .transformable
        case .objectIDAttributeType:
            return .objectID
        case .undefinedAttributeType:
            return .undefined
        case .UUIDAttributeType:
            return .string
        case .URIAttributeType:
            return .string
        }
    }
}
