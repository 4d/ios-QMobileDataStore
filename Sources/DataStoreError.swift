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
    
    /// Message from underlying error if core data error
    /// https://developer.apple.com/reference/coredata/1535452-validation_error_codes?language=swift
    public var coreDataMessage: String? {
        if error._domain == NSCocoaErrorDomain {
            let code = error._code
            if code == NSFileReadUnknownError /*256*/{
                return "Could not read data store file"
            } else {
                return CoreDataStore.message(for: code)
            }
        }
        return nil
    }

}

extension DataStoreError: LocalizedError {
    public var errorDescription: String? {
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
    
    public var failureReason: String? {
        return (error as? LocalizedError)?.failureReason ?? coreDataMessage
    }
    
    public var recoverySuggestion: String? {
        return (error as? LocalizedError)?.recoverySuggestion
    }
    
    public var helpAnchor: String? {
        return (error as? LocalizedError)?.helpAnchor
    }
}
