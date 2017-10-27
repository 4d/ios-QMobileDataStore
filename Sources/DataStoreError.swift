//
//  DataStoreError.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 22/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import Result

/// An error from data store
public struct DataStoreError: Error {

    /// The underlying error.
    public let error: Error

    public init(_ error: Error) {
        self.error = error
    }

}

extension DataStoreError: ErrorConvertible {

    public static func error(from error: Error) -> DataStoreError {
        if let error = error as? DataStoreError {
            return error
        } else {
            return DataStoreError(error)
        }
    }

}

extension DataStoreError: LocalizedError {}
