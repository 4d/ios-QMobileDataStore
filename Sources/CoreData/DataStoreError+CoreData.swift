//
//  DataStoreError+CoreData.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 23/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import CoreData

extension DataStoreError {

    /// Message from underlying error if core data error
    /// https://developer.apple.com/reference/coredata/1535452-validation_error_codes?language=swift
    public var coreDataMessage: String? {
        guard error._domain == NSCocoaErrorDomain else {
            return nil
        }
        let code = error._code
        if code == NSFileReadUnknownError /*256*/{
            return "Could not read data store file"
        } else {
            return CoreDataStore.message(for: code)
        }
    }

    public var errorCode: CocoaError.Code? {
        switch error._domain {
        case NSCocoaErrorDomain:
            return CocoaError.Code(rawValue: error._code)
        default:
            return nil
        }
    }

}
extension CocoaError.Code {
    public var errorDescription: String? {
        return CoreDataStore.message(for: self.rawValue)
    }
}

func switchKey<T, U>(_ myDict: inout [T:U], from: T, to: T) {
    if let entry = myDict.removeValue(forKey: from) {
        myDict[to] = entry
    }
}

extension DataStoreError: LocalizedError {
    public var errorDescription: String? {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        if let range = message.range(of: "(Cocoa error"),
            let errorCode = errorCode, let errorDescription = errorCode.errorDescription {
            return message.substring(to: range.lowerBound) + "(\(errorDescription): \(String(describing: errorCode.rawValue))"
        } else {
            return message
        }
    }

    public var failureReason: String? {
        if let reason = (error as? LocalizedError)?.failureReason {
            return reason
        }
        if let errorCode = errorCode, let errorDescription = errorCode.errorDescription {
            let reason = errorDescription

            if let userInfo = self.error._userInfo as? [String: AnyObject] {
                var userInfo = userInfo
                userInfo.removeValue(forKey: NSLocalizedDescriptionKey)

                switchKey(&userInfo, from: NSValidationObjectErrorKey, to: "Record".localized)
                switchKey(&userInfo, from: NSValidationKeyErrorKey, to: "Field".localized)
                switchKey(&userInfo, from: NSValidationPredicateErrorKey, to: "Predicate".localized)
                switchKey(&userInfo, from: NSValidationValueErrorKey, to: "Value".localized)

                switchKey(&userInfo, from: NSAffectedObjectsErrorKey, to: "Records".localized)
                switchKey(&userInfo, from: NSAffectedStoresErrorKey, to: "DataStore".localized)

                return "\(reason) \(userInfo)"
            }

            return reason
        }
        return nil
    }

    public var recoverySuggestion: String? {
        return (error as? LocalizedError)?.recoverySuggestion
    }

    public var helpAnchor: String? {
        return (error as? LocalizedError)?.helpAnchor
    }
}

extension String {

    var localized: String {
        return NSLocalizedString(self, bundle: Bundle(for: CoreDataStore.self), comment: "")
    }

    func localized(with comment: String = "", bundle: Bundle = Bundle(for: CoreDataStore.self)) -> String {
        return NSLocalizedString(self, bundle: bundle, comment: comment)
    }

}
