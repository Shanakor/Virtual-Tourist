//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Niklas Rammerstorfer on 05.01.18.
//  Copyright © 2018 Niklas Rammerstorfer. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController {

    // MARK: IBOutlets
    
    @IBOutlet weak var mapView: MKMapView!

    // MARK: Properties

    let photoPersistenceController = PhotoPersistenceController.shared

    var annotation: MKAnnotation!
    var transientPhotoAlbum: TransientPhotoAlbum?
    var transientPhotos: [TransientPhoto]?

    var photos = [Photo](){
        didSet{
            print(photos)
        }
    }

    // MARK: Life Cycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        mapView.addAnnotation(annotation)
        mapView.showAnnotations([annotation], animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        loadPhotoAlbum()
    }

    // TODO: Replace print(error) everywhere with UIAlertDialogs.

    private func loadPhotoAlbum() {

        // PhotoAlbum metadata.

        let travelLocation = TransientTravelLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)

        FlickrAPIClient.shared.getPhotoAlbumMetadata(travelLocation: travelLocation,
                photoAlbum: nil){
            transientPhotoAlbum, transientPhotos, error in

            guard error == nil else{
                print(error!)
                return
            }

            self.transientPhotoAlbum = transientPhotoAlbum
            self.transientPhotos = transientPhotos

            self.loadPhotoData()
        }
    }

    private func loadPhotoData() {

        FlickrAPIClient.shared.downloadPhotoData(self.transientPhotos!,
                progressHandler: {
                    transientPhoto, error in

                    guard error == nil else{
                        print(error!)
                        return
                    }

                    let photo = Photo(url: transientPhoto.url, imageData: transientPhoto.imageData!,
                            context: self.photoPersistenceController.coreDataStack.context)

                    self.photos.append(photo)
                },
                completionHandler: {error in if error != nil {print(error!)}})
    }
}
