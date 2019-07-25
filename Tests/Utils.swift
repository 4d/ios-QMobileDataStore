//
//  Utils.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 24/07/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import XCTest
@testable import QMobileDataStore

import Prephirences
import Foundation

import Result
import CoreData

import MomXML
import SWXMLHash


let modelString = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<model type="com.apple.IDECoreDataModeler.DataModel" documentVersion="1.0" lastSavedToolsVersion="14490.99" systemVersion="18F132" minimumToolsVersion="Automatic" sourceLanguage="Swift" userDefinedModelVersionIdentifier="">
<entity name="Entity" representedClassName="Entity" syncable="YES" codeGenerationType="class">
<attribute name="attribute" optional="YES" attributeType="Integer 16" defaultValueString="0" usesScalarValueType="YES" syncable="YES"/>
<attribute name="attribute1" optional="YES" attributeType="Integer 32" defaultValueString="0" usesScalarValueType="YES" syncable="YES"/>
<attribute name="attribute2" optional="YES" attributeType="Integer 64" defaultValueString="0" usesScalarValueType="YES" syncable="YES"/>
<attribute name="attribute3" optional="YES" attributeType="Decimal" defaultValueString="0.0" syncable="YES"/>
<attribute name="attribute4" optional="YES" attributeType="Double" defaultValueString="0.0" usesScalarValueType="YES" syncable="YES"/>
<attribute name="attribute5" optional="YES" attributeType="Float" defaultValueString="0.0" usesScalarValueType="YES" syncable="YES"/>
<attribute name="attribute6" optional="YES" attributeType="String" syncable="YES"/>
<attribute name="attribute7" optional="YES" attributeType="Boolean" usesScalarValueType="YES" syncable="YES"/>
<attribute name="attribute8" optional="YES" attributeType="Date" usesScalarValueType="NO" syncable="YES"/>
<attribute name="attribute9" optional="YES" attributeType="Binary" syncable="YES"/>
<attribute name="attribute10" optional="YES" attributeType="Transformable" syncable="YES"/>
<relationship name="entity0relation1" optional="YES" maxCount="1" deletionRule="Cascade" destinationEntity="Entity1" inverseName="entity1relation1" inverseEntity="Entity1" syncable="YES"/>
<relationship name="entity0relation2" optional="YES" toMany="YES" deletionRule="Nullify" destinationEntity="Entity2" inverseName="entity2relation1" inverseEntity="Entity2" syncable="YES"/>
</entity>
<entity name="Entity1" representedClassName="Entity1" syncable="YES" codeGenerationType="class">
<attribute name="attribute" optional="YES" attributeType="Boolean" usesScalarValueType="YES" syncable="YES"/>
<attribute name="attribute1" attributeType="String" syncable="YES"/>
<relationship name="entity1relation1" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="Entity" inverseName="entity0relation1" inverseEntity="Entity" syncable="YES"/>
</entity>
<entity name="Entity2" representedClassName="Entity2" syncable="YES" codeGenerationType="class">
<relationship name="entity2relation1" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="Entity" inverseName="entity0relation2" inverseEntity="Entity" syncable="YES"/>
</entity>
<entity name="Entity3" representedClassName="Entity3" syncable="YES" codeGenerationType="class"/>
<entity name="Entity4" representedClassName="Entity4" syncable="YES" codeGenerationType="class"/>
<elements>
<element name="Entity" positionX="-1205.18359375" positionY="-128.09765625" width="128" height="238"/>
<element name="Entity1" positionX="-458.74609375" positionY="-156.75390625" width="128" height="88"/>
<element name="Entity2" positionX="-403.99609375" positionY="15.84375" width="128" height="58"/>
<element name="Entity3" positionX="-444.76171875" positionY="109.26953125" width="128" height="43"/>
<element name="Entity4" positionX="-442.9140625" positionY="229.890625" width="128" height="45"/>
</elements>
</model>
"""

extension NSManagedObjectModel {

    static var coreDataModel: NSManagedObjectModel {
        let xml = SWXMLHash.parse(modelString)
        guard let parsedMom = MomXML(xml: xml) else {
            return NSManagedObjectModel()
        }
        return parsedMom.model.coreData
    }

}
extension ProcessInfo {
    // true if swift test
    static var isSwiftRuntime: Bool {
        guard let envVar = ProcessInfo.processInfo.environment["_"] else { return false }
        return envVar == "/usr/bin/swift"
    }
}

public class DataStoreFactoryTest {

    // Use a decoded model from xml string. By default true with swift test, false in xcode
    static var inMemoryModel: Bool {
        return ProcessInfo.isSwiftRuntime
    }

    static var dataStore: DataStore {
        if DataStoreFactoryTest.inMemoryModel {
            CoreDataObjectModel.default = CoreDataObjectModel.callback{
                return(NSManagedObjectModel.coreDataModel, "testModel")
            }
        }

        Bundle.dataStore = Bundle(for: DataStoreFactoryTest.self)
        return DataStoreFactory.dataStore
    }

}
