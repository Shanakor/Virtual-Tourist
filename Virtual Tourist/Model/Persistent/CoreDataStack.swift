//
// Created by Niklas Rammerstorfer on 05.01.18.
// Copyright (c) 2018 Niklas Rammerstorfer. All rights reserved.
//

import CoreData

struct CoreDataStack {

    // MARK: Properties

    private let model: NSManagedObjectModel
    internal let coordinator: NSPersistentStoreCoordinator
    private let modelURL: URL
    internal let dbURL: URL
    let mainContext: NSManagedObjectContext
    let backgroundContext: NSManagedObjectContext

    // MARK: Initializers

    init?(modelName: String) {

        // Assumes the model is in the main bundle
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            print("Unable to find \(modelName) in the main bundle")
            return nil
        }

        self.modelURL = modelURL

        // Try to create the model from the URL
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            print("unable to create a model from \(modelURL)")
            return nil
        }
        self.model = model

        // Create the store coordinator
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)

        // Create a background context, for concurrent saving.
        backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.persistentStoreCoordinator = coordinator

        // create a context and add connect it to the coordinator
        mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        mainContext.parent = backgroundContext

        // Add a SQLite store located in the documents folder
        let fm = FileManager.default

        guard let docUrl = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Unable to reach the documents folder")
            return nil
        }

        self.dbURL = docUrl.appendingPathComponent("model.sqlite")

        // Options for migration
        let options = [NSInferMappingModelAutomaticallyOption: true,NSMigratePersistentStoresAutomaticallyOption: true]

        do {
            try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: options as [NSObject : AnyObject]?)
        } catch {
            print("unable to add store at \(dbURL)")
        }
    }

    // MARK: Utils

    func addStoreCoordinator(_ storeType: String, configuration: String?, storeURL: URL, options : [NSObject:AnyObject]?) throws {
        try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dbURL, options: nil)
    }
}

// MARK: - CoreDataStack (Removing Data)

internal extension CoreDataStack  {

    func dropAllData() throws {
        // delete all the objects in the db. This won't delete the files, it will
        // just leave empty tables.
        try coordinator.destroyPersistentStore(at: dbURL, ofType:NSSQLiteStoreType , options: nil)
        try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: nil)
    }
}

// MARK: - CoreDataStack (Save Data)

extension CoreDataStack {

    func saveMainContext() throws {
        if mainContext.hasChanges {
            try mainContext.save()
        }
    }

    func saveBackgroundContext() throws {
        if backgroundContext.hasChanges {
            try backgroundContext.save()
        }
    }
}

// MARK: - CoreDataStack (Batch Processing in the Background)

extension CoreDataStack {

    typealias Batch = (_ workerContext: NSManagedObjectContext) -> ()

    func performBackgroundBatchOperation(_ batch: @escaping Batch) {

        backgroundContext.perform() {
            batch(self.backgroundContext)
        }
    }
}
