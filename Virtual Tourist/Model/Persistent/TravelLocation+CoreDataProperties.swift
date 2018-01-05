//
//  TravelLocation+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Niklas Rammerstorfer on 05.01.18.
//  Copyright © 2018 Niklas Rammerstorfer. All rights reserved.
//
//

import Foundation
import CoreData


extension TravelLocation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TravelLocation> {
        return NSFetchRequest<TravelLocation>(entityName: "TravelLocation")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var photoAlbum: PhotoAlbum?

}
