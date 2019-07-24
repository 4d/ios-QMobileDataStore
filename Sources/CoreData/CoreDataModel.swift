//
//  CoreDataModel.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 04/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import CoreData

public enum CoreDataObjectModel {

    /// a default core data store
    public static var `default`: CoreDataObjectModel = .named(Bundle.dataStore[Bundle.dataStoreKey] as? String ?? "Structures", Bundle.dataStore)

    case named(String, Bundle)
    case merged([Bundle]?)
    case url(URL)
    case callback(() -> (NSManagedObjectModel, String))

    func model() -> NSManagedObjectModel? {
        switch self {
        case .merged(let bundles):
            return NSManagedObjectModel.mergedModel(from: bundles)
        case .named(let name, let bundle):
            if let url = bundle.url(forResource: name, withExtension: "momd") {
                return NSManagedObjectModel(contentsOf: url)
            }
            logger.error("model name is not well defined in bundle, check Bundle.dataStoreKey value and Bundle.dataStore: \(name), \(bundle)")
            // model name is not well defined in bundle, check Bundle.dataStoreKey value and Bundle.dataStore
            return nil
        case .url(let url):
            return NSManagedObjectModel(contentsOf: url)
        case .callback(let builder):
            return builder().0
        }
    }

    func name() -> String {
        switch self {
        case .merged:
            return "mergerd" + UUID().uuidString
        case .named(let name, _):
            return name
        case .url(let url):
            return url.path
        case .callback(let builder):
            return builder().1
        }
    }
}
