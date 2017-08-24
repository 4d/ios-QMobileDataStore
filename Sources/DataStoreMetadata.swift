//
//  DataStoreMetadata.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 22/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

public protocol DataStoreMetadata {

    subscript(key: String) -> Any? { get set }
}
