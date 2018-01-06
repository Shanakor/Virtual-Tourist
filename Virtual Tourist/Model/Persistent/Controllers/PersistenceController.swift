//
// Created by Niklas Rammerstorfer on 05.01.18.
// Copyright (c) 2018 Niklas Rammerstorfer. All rights reserved.
//

import UIKit
import CoreData

class PersistenceController {

    // MARK: Properties

    static let shared = PersistenceController()

    let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack

    // MARK: Initialisation

    private init() {}

}

// MARK: TravelLocation Convenience Methods

extension PersistenceController{

    func persistTravelLocation(lat: Double, lon: Double){
        let travelLocation = TravelLocation(latitude: lat, longitude: lon, context: coreDataStack.context)

        do{
            try coreDataStack.saveContext()
        }
        catch{
            print("Unable to persist TravelLocation:\n\(travelLocation)")
        }
    }

    func fetchAllTravelLocations() -> [TravelLocation]{
        let allTravelLocationsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: TravelLocation.entityName)
        var travelLocations = [TravelLocation]()

        do {
            let fetchedObjects = try coreDataStack.context.fetch(allTravelLocationsFetchRequest)

            for obj in fetchedObjects {
                travelLocations.append(obj as! TravelLocation)
            }
        }
        catch {
            print("Unable to fetch TravelLocations!")
        }

        return travelLocations
    }
}
