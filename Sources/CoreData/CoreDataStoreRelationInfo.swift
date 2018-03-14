//
//  CoreDataStoreRelationInfo.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 14/03/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation
import CoreData

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
    var userInfo: [AnyHashable: Any]? {
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
