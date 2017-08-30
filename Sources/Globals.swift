//
//  Globals.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 28/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

// Here come CoreData dependency to break if needed, by chosing an other default type
public let dataStore: DataStore = CoreDataStore.default

// XXX could use also a factory, allowing to change the default value in it
/*public class DataStoreFactory {

    public static var dataStore: DataStore = CoreDataStore.default

}*/
