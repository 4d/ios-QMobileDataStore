//
//  DataStoreError+CoreData.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 23/08/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import CoreData

extension DataStoreError: CustomDebugStringConvertible {

    /// Message from underlying error if core data error
     public var debugDescription: String {
        guard error._domain == NSCocoaErrorDomain else {
            return error.localizedDescription
        }
        return CocoaError.Code.message(for: error._code) ?? error.localizedDescription
    }
}

extension DataStoreError {
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

    public var coreDataDescription: String? {
        return CocoaError.Code.message(for: self.rawValue)
    }

    /// Return for code a message from cocoa doc
    // https://developer.apple.com/reference/coredata/1535452-validation_error_codes?language=swift
    static func message(for code: Int) -> String? { // swiftlint:disable:this cyclomatic_complexity
        switch code {
        case NSFileReadUnknownError /*256*/: return "Could not read data store file"
        case NSManagedObjectValidationError: return "generic validation error"
        case NSManagedObjectConstraintValidationError: return "one or more uniqueness constraints were violated"
        case NSValidationMultipleErrorsError: return "generic message for error containing multiple validation errors"

        case NSValidationRelationshipLacksMinimumCountError: return "to-many relationship with too few destination objects"
        case NSValidationRelationshipExceedsMaximumCountError: return "bounded, to-many relationship with too many destination objects"
        case NSValidationRelationshipDeniedDeleteError: return "some relationship with NSDeleteRuleDeny is non-empty"

        case NSValidationMissingMandatoryPropertyError: return "non-optional property with a nil value"

        case NSValidationNumberTooLargeError: return "some numerical value is too large"
        case NSValidationNumberTooSmallError: return "some numerical value is too small"
        case NSValidationDateTooLateError: return "some date value is too late"
        case NSValidationDateTooSoonError: return "some date value is too soon"
        case NSValidationInvalidDateError: return "some date value fails to match date pattern"
        case NSValidationStringTooLongError: return "some string value is too long"
        case NSValidationStringTooShortError: return "some string value is too short"
        case NSValidationStringPatternMatchingError: return "some string value fails to match some pattern"

        case NSManagedObjectContextLockingError: return "can't acquire a lock in a managed object context"
        case NSPersistentStoreCoordinatorLockingError: return "can't acquire a lock in a persistent store coordinator"

        case NSManagedObjectReferentialIntegrityError: return "attempt to fire a fault pointing to an object that does not exist (we can see the store, we can't see the object)"
        case NSManagedObjectExternalRelationshipError: return "an object being saved has a relationship containing an object from another store"
        case NSManagedObjectMergeError: return "merge policy failed - unable to complete merging"
        case NSManagedObjectConstraintMergeError: return "merge policy failed - unable to complete merging due to multiple conflicting constraint violations"

        case NSPersistentStoreInvalidTypeError: return "unknown persistent store type/format/version"
        case NSPersistentStoreTypeMismatchError: return "returned by persistent store coordinator if a store is accessed that does not match the specified type"
        case NSPersistentStoreIncompatibleSchemaError: return "store returned an error for save operation (database level errors ie missing table, no permissions)"
        case NSPersistentStoreSaveError: return "unclassified save error - something we depend on returned an error"
        case NSPersistentStoreIncompleteSaveError: return "one or more of the stores returned an error during save (stores/objects that failed will be in userInfo)"
        case NSPersistentStoreSaveConflictsError: return "an unresolved merge conflict was encountered during a save.  userInfo has NSPersistentStoreSaveConflictsErrorKey"

        case NSCoreDataError: return "general Core Data error"
        case NSPersistentStoreOperationError: return "the persistent store operation failed "
        case NSPersistentStoreOpenError: return "an error occurred while attempting to open the persistent store"
        case NSPersistentStoreTimeoutError: return "failed to connect to the persistent store within the specified timeout (see NSPersistentStoreTimeoutOption)"
        case NSPersistentStoreUnsupportedRequestTypeError: return "an NSPersistentStore subclass was passed an NSPersistentStoreRequest that it did not understand"

        case NSPersistentStoreIncompatibleVersionHashError: return "entity version hashes incompatible with data model"
        case NSMigrationError: return "general migration error"
        case NSMigrationConstraintViolationError: return "migration failed due to a violated uniqueness constraint"
        case NSMigrationCancelledError: return "migration failed due to manual cancellation"
        case NSMigrationMissingSourceModelError: return "migration failed due to missing source data model"
        case NSMigrationMissingMappingModelError: return "migration failed due to missing mapping model"
        case NSMigrationManagerSourceStoreError: return "migration failed due to a problem with the source data store"
        case NSMigrationManagerDestinationStoreError: return "migration failed due to a problem with the destination data store"
        case NSEntityMigrationPolicyError: return "migration failed during processing of the entity migration policy "

        case NSSQLiteError: return "general SQLite error "

        case NSInferredMappingModelError: return "inferred mapping model creation error"
        case NSExternalRecordImportError: return "general error encountered while importing external records"
        default: return nil
        }
    }

}

func switchKey<T, U>(_ myDict: inout [T: U], from: T, to: T) {
    if let entry = myDict.removeValue(forKey: from) {
        myDict[to] = entry
    }
}

extension DataStoreError {

    public var errorDescription: String? {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        if let range = message.range(of: "(Cocoa error"),
            let errorCode = errorCode, let errorDescription = errorCode.coreDataDescription?.localized {
            return message[..<range.lowerBound] + "(\(errorDescription): \(String(describing: errorCode.rawValue))"
        } else {
            return message
        }
    }

    public var failureReason: String? {
        if let reason = (error as? LocalizedError)?.failureReason {
            return reason
        }
        if let errorCode = errorCode, let errorDescription = errorCode.coreDataDescription {
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
