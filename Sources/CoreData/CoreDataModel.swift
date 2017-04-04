//
//  CoreDataModel.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 04/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import CoreData

enum CoreDataObjectModel {

    case named(String, Bundle)
    case merged([Bundle]?)
    case url(URL)

    func model() -> NSManagedObjectModel? {
        switch self {
        case .merged(let bundles):
            return NSManagedObjectModel.mergedModel(from: bundles)
        case .named(let name, let bundle):
            return NSManagedObjectModel(contentsOf: bundle.url(forResource: name, withExtension: "momd")!)
        case .url(let url):
            return NSManagedObjectModel(contentsOf: url)
        }
    }

    func name() -> String {
        switch self {
        case .merged(_):
            return "mergerd" + UUID().uuidString
        case .named(let name, _):
            return name
        case .url(let url):
            return url.path
        }
    }
}
