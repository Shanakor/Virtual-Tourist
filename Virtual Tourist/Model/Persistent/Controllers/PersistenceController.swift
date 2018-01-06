//
// Created by Niklas Rammerstorfer on 05.01.18.
// Copyright (c) 2018 Niklas Rammerstorfer. All rights reserved.
//

import UIKit
import CoreData

class PersistenceController {

    // MARK: Properties

    static let shared = PersistenceController()

    private let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack

    var context: NSManagedObjectContext{
        get{
            return coreDataStack.context
        }
    }

    // MARK: Initialisation

    private init() {}

    // MARK: Convenience Methods

    func saveContext(){
        do {
            try coreDataStack.saveContext()
        }
        catch{
            print(error)
        }
    }
}

// MARK: TravelLocation Convenience Methods

extension PersistenceController{

    func fetchAllTravelLocations() -> [TravelLocation]{
        let fr = NSFetchRequest<TravelLocation>(entityName: TravelLocation.entityName)
        var travelLocations = [TravelLocation]()

        do {
            let fetchedTravelLocations = try context.fetch(fr)

            for tl in fetchedTravelLocations {
                travelLocations.append(tl)
            }
        }
        catch {
            print("Unable to fetch TravelLocations!")
        }

        return travelLocations
    }

    func fetchTravelLocation(lat: Double, lon: Double) -> TravelLocation?{
        let fr = NSFetchRequest<TravelLocation>(entityName: TravelLocation.entityName)
        fr.predicate = NSPredicate(format: "latitude = %d AND longitude = %d", argumentArray: [lat, lon])

        do {
            let fetchedTravelLocations = try context.fetch(fr)

            guard fetchedTravelLocations.count > 0 else{
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
