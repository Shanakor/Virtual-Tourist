//
// Created by Niklas Rammerstorfer on 05.01.18.
// Copyright (c) 2018 Niklas Rammerstorfer. All rights reserved.
//

import UIKit
import CoreData

class CoreDataStackFacade {

    // MARK: Properties

    static let shared = CoreDataStackFacade()

    private let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack

    // MARK: Initialization

    private init() {}

    // MARK: Convenience Methods

    func saveMainContext(){
        do {
            try coreDataStack.saveMainContext()
        }
        catch{
            print("Error while persisting mainContext: \n \(error)")
        }
    }

    func saveBackgroundContext(){
        do {
            try coreDataStack.saveBackgroundContext()
        }
        catch{
            print("Error while persisting backgroundContext: \n \(error)")
        }
    }

    typealias Batch = (_ workerContext: NSManagedObjectContext) -> ()

    func performBackgroundBatchOperation(_ batch: @escaping Batch) {
        coreDataStack.performBackgroundBatchOperation{
            workerContext in self.coreDataStack.performBackgroundBatchOperation(batch)
        }
    }
}

// MARK: TravelLocation Convenience Methods

extension CoreDataStackFacade {

    func fetchAllTravelLocationsAsync() -> [TravelLocation]{
        let fr = NSFetchRequest<TravelLocation>(entityName: TravelLocation.entityName)
        var travelLocations = [TravelLocation]()

        do {
            let fetchedTravelLocations = try coreDataStack.backgroundContext.fetch(fr)

            for tl in fetchedTravelLocations {
                travelLocations.append(tl)
            }
        } catch {
            print("Unable to fetch TravelLocations!")
        }

        return travelLocations
    }

    func fetchTravelLocationAsync(lat: Double, lon: Double) -> TravelLocation?{

        let fr = NSFetchRequest<TravelLocation>(entityName: TravelLocation.entityName)
        fr.predicate = NSPredicate(format: "latitude = %d AND longitude = %d", argumentArray: [lat, lon])

        do {
            let fetchedTravelLocations = try coreDataStack.backgroundContext.fetch(fr)

            guard fetchedTravelLocations.count > 0 else {
                print("Unable to find a TravelLocation with coordinates: lat=\(lat), lon=\(lon)!")
                return nil
            }

            return fetchedTravelLocations[0]
        }
        catch {
            print(error)
        }

        return nil
    }
}
