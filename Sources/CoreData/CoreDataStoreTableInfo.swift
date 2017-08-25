//
//  CoreDataStoreTable.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 24/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStoreTableInfo: DataStoreTableInfo {
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
    lazy var fields: [DataStoreFieldInfo] = {
        return self.entity.attributesByName.values.map { CoreDataStoreFieldInfo(attribute: $0) }
    }()

    lazy var fieldsByName: [String : DataStoreFieldInfo] = {
        return Dictionary(self.entity.attributesByName.map {  ($0, CoreDataStoreFieldInfo(attribute: $1)) })
    }()
    lazy var relationshipsByName: [String : DataStoreRelationInfo] = {
        return Dictionary(self.entity.relationshipsByName.map {  ($0, CoreDataStoreRelationInfo(relation: $1)) })
    }()

    func relationships(for table: DataStoreTableInfo) -> [DataStoreRelationInfo] {
        guard let table = table as? CoreDataStoreTableInfo else {
            assertionFailure("Cannot mix table info from different store type") // or we must be able to get entityDescription by name
            return []
        }
        return entity.relationships(forDestination: table.entity).map { CoreDataStoreRelationInfo(relation: $0) }
    }

    var isAbstract: Bool {
        return self.entity.isAbstract
    }
    var name: String {
        //swiftlint:disable:next force_cast
        return self.entity.name!
    }

    var localizedName: String {
        let name = self.name
        // https://developer.apple.com/documentation/coredata/nsmanagedobjectmodel/1506846-localizationdictionary
        if let value = self.entity.managedObjectModel.localizationDictionary?["Entity/\(name)"] {
            return value
        }
        return name
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

class CoreDataStoreRelationInfo: DataStoreRelationInfo {

    let relation: NSRelationshipDescription
    init(relation: NSRelationshipDescription) {
        self.relation = relation
    }

    lazy var destinationTable: DataStoreTableInfo? = {
        guard let table = self.relation.destinationEntity else {
            return nil
        }
        return CoreDataStoreTableInfo(entity: table)
    }()

    lazy var inverseRelationship: DataStoreRelationInfo? = {
        guard let inverse = self.relation.inverseRelationship else {
            return nil
        }
        return CoreDataStoreRelationInfo(relation: inverse)
    }()

    var maxCount: Int {
        return self.relation.maxCount
    }

    var minCount: Int {
        return self.relation.minCount
    }

    var deleteRule: DeleteRule {
        return self.relation.deleteRule.mapped
    }

    var isToMany: Bool {
        return self.relation.isToMany
    }

    var isOrdered: Bool {
        return self.relation.isOrdered
    }
    var isOptional: Bool {
        return self.relation.isOptional
    }
    var name: String {
        return self.relation.name
    }
    var userInfo: [AnyHashable : Any]? {
        return self.relation.userInfo
    }

}

extension NSDeleteRule {

    var mapped: DeleteRule {
        if let rule = DeleteRule(rawValue: self.rawValue) {
            return rule
        }
        return .noAction
    }
}

class CoreDataStoreFieldInfo: DataStoreFieldInfo {

    let attribute: NSAttributeDescription

    init( attribute: NSAttributeDescription) {
        self.attribute = attribute
    }

    var name: String {
        return self.attribute.name
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
