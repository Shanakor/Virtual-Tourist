//
//  TravelLocation+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Niklas Rammerstorfer on 05.01.18.
//  Copyright © 2018 Niklas Rammerstorfer. All rights reserved.
//
//

import Foundation
import CoreData


public class TravelLocation: NSManagedObject {
    static let entityName = "TravelLocation"

    convenience init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        let entityName = "TravelLocation"

        // An EntityDescription is an object that has access to all
        // the information you provided in the Entity part of the model
        // you need it to create an instance of this class.
        if let ent = NSEntityDescription.entity(forEntityName: entityName, in: context) {
            self.init(entity: ent, insertInto: context)

            self.latitude = latitude
            self.longitude = longitude
        } else {
            fatalError("Unable to find Entity name '\(entityName)'!")
        }
    }
}
