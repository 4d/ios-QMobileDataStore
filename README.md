# QMobileDataStore

[Development #88591](https://project.wakanda.org/issues/88591)

Main class is `DataStore`

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
