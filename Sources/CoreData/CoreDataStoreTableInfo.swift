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
    var userInfo: [AnyHashable: Any]? {
        get {
            return self.entity.userInfo
        }
        set {
            self.entity.userInfo = newValue
        }
    }
    lazy var fields: [DataStoreFieldInfo] = {
        return self.entity.attributesByName.values.map { CoreDataStoreFieldInfo(attribute: $0) }
    }()

    lazy var fieldsByName: [String: DataStoreFieldInfo] = {
        return Dictionary(uniqueKeysWithValues: self.entity.attributesByName.map {  ($0, CoreDataStoreFieldInfo(attribute: $1)) })
    }()

    lazy var relationships: [DataStoreRelationInfo] = {
        return self.entity.relationshipsByName.map { CoreDataStoreRelationInfo(relation: $1) }
    }()
    lazy var relationshipsByName: [String: DataStoreRelationInfo] = {
        return Dictionary(uniqueKeysWithValues: self.entity.relationshipsByName.map {  ($0, CoreDataStoreRelationInfo(relation: $1)) })
    }()

    lazy var properties: [DataStorePropertyInfo] = {
        return self.entity.properties.compactMap { property -> DataStorePropertyInfo? in
            if let relationship = property as? NSRelationshipDescription {
                return CoreDataStoreRelationInfo(relation: relationship)
            } else if let attribute = property as? NSAttributeDescription {
                return CoreDataStoreFieldInfo(attribute: attribute)
            }
            // + could add other type of properties here (core data is fetched one
            return nil
        }
    }()

    lazy var propertiesByName: [String: DataStorePropertyInfo] = {
        return Dictionary(uniqueKeysWithValues: self.entity.propertiesByName.compactMap { name, property -> (String, DataStorePropertyInfo)? in
            if let relationship = property as? NSRelationshipDescription {
                return (name, CoreDataStoreRelationInfo(relation: relationship))
            } else if let attribute = property as? NSAttributeDescription {
                return (name, CoreDataStoreFieldInfo(attribute: attribute))
            }
            // + could add other type of properties here (core data is fetched one
            return nil
        })
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
        return self.entity.name ?? self.entity.managedObjectClassName
    }

    var localizedName: String {
        let name = self.name
        // https://developer.apple.com/documentation/coredata/nsmanagedobjectmodel/1506846-localizationdictionary
        if let value = self.entity.managedObjectModel.localizationDictionary?["Entity/\(name)"] {
            return value
        }
        return name
    }

    var label: String? {
        return self.entity.managedObjectModel.localizationDictionary?["Entity/\(name)"]
    }

    var shortLabel: String? {
        return self.entity.managedObjectModel.localizationDictionary?["Entity/\(name)@short"]
    }

}

extension NSManagedObject {
    var dataStoreTableInfo: DataStoreTableInfo {
        return CoreDataStoreTableInfo(entity: self.entity)
    }
}
