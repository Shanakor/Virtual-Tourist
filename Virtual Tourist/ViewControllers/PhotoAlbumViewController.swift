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

    var annotation: MKAnnotation!

    // MARK: Life Cycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        mapView.addAnnotation(annotation)
        mapView.showAnnotations([annotation], animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        FlickrAPIClient.shared.getPhotoAlbumInformation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude,
                completionHandler: {_, _ in })
    }
}
