//
//  DataStoreFactory.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 28/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

/// Object which contain the data store used.
public class DataStoreFactory {

    /// The data store. By default : core data store
    public static var dataStore: DataStore = CoreDataStore.default

}
