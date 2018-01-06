//
// Created by Niklas Rammerstorfer on 06.01.18.
// Copyright (c) 2018 Niklas Rammerstorfer. All rights reserved.
//

import Foundation
import CoreData

class TransientPersistentConversionBridge {

    // MARK: TransientTravelLocation

    static func toTransientTravelLocation(_ travelLocation: TravelLocation) -> TransientTravelLocation{
        return TransientTravelLocation(latitude: travelLocation.latitude, longitude: travelLocation.longitude)
    }

    // MARK: TransientPhotoAlbum

    static func toTransientPhotoAlbum(_ photoAlbum: PhotoAlbum) -> TransientPhotoAlbum{
        return TransientPhotoAlbum(page: photoAlbum.page, pageCount: photoAlbum.pageCount)
    }

    // MARK: TransientPhoto

    static func toTransientPhoto(_ photo: Photo) -> TransientPhoto{
        return TransientPhoto(url: photo.url!, imageData: photo.imageData)
    }

    static func toTransientPhotos(_ photos: [Photo]) -> [TransientPhoto]{
        var transPhotos = [TransientPhoto]()

        for photo in photos{
            transPhotos.append(toTransientPhoto(photo))
        }

        return transPhotos
    }

    // MARK: PhotoAlbum

    static func toPhotoAlbum(_ transientPhotoAlbum: TransientPhotoAlbum, context: NSManagedObjectContext) -> PhotoAlbum{
        return PhotoAlbum(page: transientPhotoAlbum.page, pageCount: transientPhotoAlbum.pageCount!, context: context)
    }

    // MARK: Photo

    static func toPhoto(_ transientPhoto: TransientPhoto, context: NSManagedObjectContext) -> Photo{
        return Photo(url: transientPhoto.url, imageData: transientPhoto.imageData, context: context)
    }
}
