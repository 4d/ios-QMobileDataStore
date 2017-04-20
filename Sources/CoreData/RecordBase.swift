//
//  RecordBase.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 29/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import CoreData

import Result

public typealias RecordBase = NSManagedObject

public extension NSManagedObjectContext {

    public static var `default`: NSManagedObjectContext {
        return CoreDataStore.default.viewContext
    }

    public static func newBackgroundContext() -> NSManagedObjectContext {
        return CoreDataStore.default.newBackgroundContext()
    }

    /*fileprivate struct Key {
     static let coreDataStore = UnsafeRawPointer(bitPattern: Selector(("coreDataStore")).hashValue)
     }
     internal (set) var coreDataStore: CoreDataStore? {
     get {
     if let obj = objc_getAssociatedObject(self, Key.coreDataStore) as? CoreDataStore {
     return obj
     }
     return nil
     }
     set {
     objc_setAssociatedObject(self, Key.coreDataStore, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
     }
     }*/

}

// MARK : record bqse
extension RecordBase {

    /// Access record attribute value using string key
    open subscript(key: String) -> Any? {
        get {
            return self.value(forKey: key)
        }
        set {
            if hasKey(key) {
                self.setValue(newValue, forKey: key)
            } /*else {
             // not key value coding-compliant for the key
             }*/
        }
    }

    open func hasKey(_ key: String) -> Bool {
        return self.entity.propertiesByName[key] != nil // CLEAN optimize how to known if record KVC compliant to key
    }

    open override func value(forUndefinedKey key: String) -> Any? {
        assertionFailure("Undefined field '\(key) for record \(self)")
        return nil
    }

    open var predicate: NSPredicate {
        return NSPredicate(format: "SELF = %@", objectID)
    }

    /*open func willSave() {
         // can set here timestamps to know objec =t with modification since last SyNCHRO
    }*/

}
/*
fileprivate func uniqueToStdHandler(_ uniqueHandler: @escaping RecordBase.FunctionUniqueCompletionHandler) -> RecordBase.FunctionCompletionHandler {
    let handler: RecordBase.FunctionCompletionHandler = { result in
        switch result {
        case .failure(let error):
            uniqueHandler(.failure(error))
        case .success(let results):
            uniqueHandler(.success(results.first ?? 0))
        }
    }
    return handler
}
 */
/*
public extension RecordBase {

    public typealias FunctionCompletionHandler = (Result<[Double], DataStoreError>) -> Void
    public typealias FunctionUniqueCompletionHandler = (Result<Double, DataStoreError>) -> Void

    public class func function(_ function: String, fieldName: [String], predicate: NSPredicate? = nil, context: NSManagedObjectContext = NSManagedObjectContext.default, completionHandler: @escaping FunctionCompletionHandler) {

        var expressionsDescription = [NSExpressionDescription]()
        for field in fieldName {
            let expression = NSExpression(forKeyPath: field)
            let expressionDescription = NSExpressionDescription()
            expressionDescription.expression = NSExpression(forFunction: function, arguments: [expression])
            expressionDescription.expressionResultType = NSAttributeType.doubleAttributeType
            expressionDescription.name = field
            expressionsDescription.append(expressionDescription)
        }

        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = self.fetchRequest()
        fetchRequest.propertiesToFetch = expressionsDescription
        fetchRequest.resultType = NSFetchRequestResultType.dictionaryResultType

        context.perform { _ in
            let resultValue = [Double]()
            // XXX functions on fetch request for mapping
            do {
                _ = try context.fetch(fetchRequest) as? [[String: AnyObject]]
                /*
                 for result in results ?? [] {
                 for field in fieldName {
                 let value = result.value(forKey: field) as! Double
                 
                 }*/
                completionHandler(.success(resultValue))
            } catch {
                completionHandler(.failure(DataStoreError(error)))
            }
        }

    }

    public class func sum(fieldName: [String], predicate: NSPredicate? = nil, context: NSManagedObjectContext = NSManagedObjectContext.default, completionHandler: @escaping FunctionCompletionHandler) {
        function("sum:", fieldName: fieldName, predicate: predicate, context: context, completionHandler: completionHandler)
    }

    public class func sum(fieldName: String, predicate: NSPredicate? = nil, context: NSManagedObjectContext = NSManagedObjectContext.default, completionHandler: @escaping FunctionUniqueCompletionHandler) {
        sum(fieldName: [fieldName], predicate: predicate, context: context, completionHandler: uniqueToStdHandler(completionHandler))
    }

    public class func max(fieldName: [String], predicate: NSPredicate? = nil, context: NSManagedObjectContext = NSManagedObjectContext.default, completionHandler: @escaping FunctionCompletionHandler) {
        function("max:", fieldName: fieldName, predicate: predicate, context: context, completionHandler: completionHandler)
    }

    public class func max(fieldName: String, predicate: NSPredicate? = nil, context: NSManagedObjectContext = NSManagedObjectContext.default, completionHandler: @escaping FunctionUniqueCompletionHandler) {
        max(fieldName: [fieldName], predicate: predicate, context: context, completionHandler: uniqueToStdHandler(completionHandler))
    }

    public class func min(fieldName: [String], predicate: NSPredicate? = nil, context: NSManagedObjectContext = NSManagedObjectContext.default, completionHandler: @escaping FunctionCompletionHandler) {
        function("min:", fieldName: fieldName, predicate: predicate, context: context, completionHandler: completionHandler)
    }

    public class func min( fieldName: String, predicate: NSPredicate? = nil, context: NSManagedObjectContext = NSManagedObjectContext.default, completionHandler: @escaping FunctionUniqueCompletionHandler) {
        min(fieldName: [fieldName], predicate: predicate, completionHandler: uniqueToStdHandler(completionHandler))
    }

    public class func avg(fieldName: [String], predicate: NSPredicate? = nil, context: NSManagedObjectContext = NSManagedObjectContext.default, completionHandler: @escaping FunctionCompletionHandler) {
        function("average:", fieldName: fieldName, predicate: predicate, context: context, completionHandler: completionHandler)
    }

    public class func avg(fieldName: String, predicate: NSPredicate? = nil, context: NSManagedObjectContext = NSManagedObjectContext.default, completionHandler: @escaping FunctionUniqueCompletionHandler) {
        avg(fieldName: [fieldName], predicate: predicate, context: context, completionHandler: uniqueToStdHandler(completionHandler))
    }

}
*/
