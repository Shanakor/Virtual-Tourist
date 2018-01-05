//
//  PhotoAlbum+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Niklas Rammerstorfer on 05.01.18.
//  Copyright © 2018 Niklas Rammerstorfer. All rights reserved.
//
//

import Foundation
import CoreData


extension PhotoAlbum {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PhotoAlbum> {
        return NSFetchRequest<PhotoAlbum>(entityName: "PhotoAlbum")
    }

    @NSManaged public var page: Int32
    @NSManaged public var pageCount: Int32
    @NSManaged public var photos: NSSet?
    @NSManaged public var travelLocation: TravelLocation?

}

// MARK: Generated accessors for photos
extension PhotoAlbum {

    @objc(addPhotosObject:)
    @NSManaged public func addToPhotos(_ value: Photo)

    @objc(removePhotosObject:)
    @NSManaged public func removeFromPhotos(_ value: Photo)

    @objc(addPhotos:)
    @NSManaged public func addToPhotos(_ values: NSSet)

    @objc(removePhotos:)
    @NSManaged public func removeFromPhotos(_ values: NSSet)

}
