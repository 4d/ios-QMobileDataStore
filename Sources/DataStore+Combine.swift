//
//  DataStore+Future.swift
//  QMobileDataSync
//
//  Created by Eric Marchand on 16/05/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import Combine

extension DataStore {

    public typealias PerformFuture = AnyPublisher<DataStoreContext, DataStoreError>
    public typealias PerformResult = Result<DataStoreContext, DataStoreError>

    /// Load the data store and return a Future
    public func load() -> AnyPublisher<Void, DataStoreError> {
        if isLoaded {
            return Just<Void>(())
                .setFailureType(to: DataStoreError.self)
                .eraseToAnyPublisher()
        }
        return Future<Void, DataStoreError> { self.load(completionHandler: $0) }.eraseToAnyPublisher()
    }

    /// Save the data store and return a Future
    public func save() -> Future<Void, DataStoreError> {
        return Future<Void, DataStoreError> { self.save(completionHandler: $0) }
    }

    /// Drop the data store and return a Future
    public func drop() -> Future<Void, DataStoreError> {
        return Future<Void, DataStoreError> { self.drop(completionHandler: $0) }
    }

    /// Provide a context for performing data store operation
    public func perform(_ type: QMobileDataStore.DataStoreContextType, blockName: String? = nil) -> PerformFuture {
        return Future { complete in
            let value = self.perform(type, wait: false, blockName: blockName) { context in
                complete(.success(context))
            }
            if !value {
                complete(.failure(DataStoreError(NSError(domain: NSCocoaErrorDomain, code: 134060, userInfo: [NSLocalizedDescriptionKey: "DataStore not ready"]))))
            }
        }.eraseToAnyPublisher()
    }
}
