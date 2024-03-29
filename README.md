# QMobileDataStore

[![License](https://img.shields.io/badge/license-4D-blue.svg?style=flat)](LICENSE.md)
[![Platform](http://img.shields.io/badge/platform-iOS_macOS-lightgrey.svg?style=flat)](https://developer.apple.com/resources/)
[![Language](http://img.shields.io/badge/language-swift-orange.svg?style=flat)](https://developer.apple.com/swift)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)
[![Swift](https://github.com/4d/ios-QMobileDataStore/actions/workflows/swift.yml/badge.svg)](https://github.com/4d/ios-QMobileDataStore/actions/workflows/swift.yml)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Carthage](https://github.com/4d/ios-QMobileDataStore/actions/workflows/carthage.yml/badge.svg)](https://github.com/4d/ios-QMobileDataStore/actions/workflows/carthage.yml)

This iOS framework belong to [iOS SDK](https://github.com/4d/ios-sdk) and it contains all stuff to initialize and populate the [CoreData](https://developer.apple.com/documentation/coredata) database.

## How it workds 

Main class is `DataStore`. 

An instance could be retrieved from the `DataStoreFactory`

a data store could be
- loaded
- saved
- dropped

it can store
- `Record`
- metadata (`Dictionary`)

It provide `FetchRequest` and `FetchedResultsController` on specific database Table to retrieve data

It allow to perform storage operation on foreground or background (`DataStoreContextType`) by providing a `DataStoreContext`
Within the context a Record could be
- created
- deleted
- updated

Record field could be acceded using
```swift
myRecord["<fieldName>"] // or myRecord.fieldName
```

This `DataStore` definition is implemented by `CoreDataStore`

## Dependencies

- [CoreData](https://developer.apple.com/documentation/coredata): to persist the data
- [XCGLogger](https://github.com/DaveWoodCom/XCGLogger): to log
- [Prephirences](https://github.com/DaveWoodCom/XCGLogger): to subscript [Bundle](https://developer.apple.com/documentation/foundation/bundle) values

### for testing only

- [MomXML](https://github.com/phimage/MomXML) to manipulate or create coredata model
