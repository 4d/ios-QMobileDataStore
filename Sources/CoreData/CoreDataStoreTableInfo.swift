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
        return self.entity.userInfo
    }
    lazy var fields: [DataStoreFieldInfo] = {
        return self.entity.attributesByName.values.map { CoreDataStoreFieldInfo(attribute: $0) }
    }()

    lazy var fieldsByName: [String: DataStoreFieldInfo] = {
        return Dictionary(self.entity.attributesByName.map {  ($0, CoreDataStoreFieldInfo(attribute: $1)) })
    }()

    lazy var relationships: [DataStoreRelationInfo] = {
        return self.entity.relationshipsByName.map { CoreDataStoreRelationInfo(relation: $1) }
    }()
    lazy var relationshipsByName: [String: DataStoreRelationInfo] = {
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

}
