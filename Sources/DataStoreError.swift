//
//  DataStoreError.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 22/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

/// An error from data store
public struct DataStoreError: Error {

    /// The underlying error.
    public let error: Error

    public init(_ error: Error) {
        self.error = error
    }

}
