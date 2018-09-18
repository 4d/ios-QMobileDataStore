//
//  NSPersistentStore+DataStore.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 29/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import CoreData

extension NSPersistentStore {

    public static var defaultURL: URL {
        return URL(fileURLWithPath: "/dev/null")
    }

    open var isTransient: Bool {
        guard let url =  self.url else {
            return false // or true??
        }
        return url == NSPersistentStore.defaultURL
    }

}
