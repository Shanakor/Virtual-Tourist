//
// Created by Niklas Rammerstorfer on 05.01.18.
// Copyright (c) 2018 Niklas Rammerstorfer. All rights reserved.
//

import UIKit
import CoreData

class TravelLocationPersistenceController {

    // MARK: Properties

    static let shared = TravelLocationPersistenceController()

    private let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack

    // MARK: Initialisation

    private init(){

    }

    // MARK: Convenience Methods

    func persistTravelLocation(lat: Double, lon: Double){
        let travelLocation = TravelLocation(latitude: lat, longitude: lon, context: coreDataStack.context)
        travelLocation.photoAlbum = PhotoAlbum(page: nil, pageCount: nil, context: coreDataStack.context)

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
