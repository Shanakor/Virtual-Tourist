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
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var collectionViewContainerView: UIView!
    @IBOutlet weak var noImagesContainerView: UIView!
    
    // MARK: Constants

    fileprivate struct Identifiers{
        struct Segues{
            static let EmbedCollectionViewController = "EmbedCollectionViewController"
        }
    }

    // MARK: Properties

    var annotation: MKAnnotation!
    var travelLocation: TravelLocation!

    let persistenceCtrl = PersistenceController.shared

    private var transTravelLocation: TransientTravelLocation!
    private var transPhotoAlbum: TransientPhotoAlbum!
    private var transPhotos = [TransientPhoto](){
        didSet {
            collectionViewController.transPhotos = transPhotos
        }
    }

    private var collectionViewController: PhotoCollectionViewViewController!

    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.travelLocation = persistenceCtrl.fetchTravelLocation(lat: annotation.coordinate.latitude, lon: annotation.coordinate.longitude)

        initTransientProperties()
        configureContainerViewLayout()

        self.collectionViewController.delegate = self
    }

    private func initTransientProperties() {
        transTravelLocation = TransientPersistentConversionBridge.toTransientTravelLocation(travelLocation)

        guard let photoAlbum = travelLocation.photoAlbum else{
            return
        }

        transPhotoAlbum = TransientPersistentConversionBridge.toTransientPhotoAlbum(photoAlbum)

        if let photos = photoAlbum.photos{
            transPhotos = TransientPersistentConversionBridge.toTransientPhotos(photos.allObjects as! [Photo])
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        mapView.addAnnotation(annotation)
        mapView.showAnnotations([annotation], animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if self.transPhotoAlbum == nil {
            configureUI(enabled: false)

            downloadPhotoAlbum() {
                DispatchQueue.main.async {
                    self.configureUI(enabled: true)
                    self.persistChanges()
                }
            }
        }
    }

    // MARK: IBActions
    
    @IBAction func downloadNewPage(_ sender: Any) {
        transPhotoAlbum.page = transPhotoAlbum.page + 1

        if transPhotoAlbum.page > transPhotoAlbum.pageCount!{
            transPhotoAlbum.page = 1
        }

        configureUI(enabled: false)
        downloadPhotoAlbum(){
            DispatchQueue.main.async {
                self.configureUI(enabled: true)
                self.persistChanges()
            }
        }
    }
    
    // MARK: Network Requests
    // TODO: Replace print(error) everywhere with UIAlertDialogs.

    private func downloadPhotoAlbum(completionHandler: @escaping () -> Void) {

        // PhotoAlbum metadata.

        FlickrAPIClient.shared.getPhotoMetadata(for: transTravelLocation, page: (transPhotoAlbum == nil ? 1 : transPhotoAlbum!.page)){
            transPhotoAlbum, transPhotos, error in

            guard error == nil else{
                print(error!)
                return
            }

            self.transPhotoAlbum = transPhotoAlbum
            self.transPhotos = transPhotos!

            DispatchQueue.main.async{
                // Show image label if no photos were found.
                self.configureContainerViewLayout()
            }

            self.loadPhotoData(of: transPhotos!, completionHandler: completionHandler)
        }
    }

    private func loadPhotoData(of transientPhotos: [TransientPhoto], completionHandler: @escaping () -> Void) {

        FlickrAPIClient.shared.downloadPhotoData(of: transientPhotos,
                progressHandler: {
                    transPhoto, error in

                    guard error == nil else{
                        print(error!)
                        return
                    }

                    DispatchQueue.main.async {
                        let idx = self.transPhotos.index(where: {other in transPhoto.url == other.url})
                        self.transPhotos.remove(at: idx!)
                        self.transPhotos.insert(transPhoto, at: idx!)
                    }
                },
                completionHandler: {
                    error in

                    if error != nil {
                        print(error!)
                    }

                    completionHandler()
                })
    }

    // MARK: Persistence

    private func persistChanges() {
        if let photoAlbum = travelLocation.photoAlbum{
            // Due to delete rule cascade, all photos get deleted also.
            persistenceCtrl.context.delete(photoAlbum)
        }

        let photoAlbum = TransientPersistentConversionBridge.toPhotoAlbum(transPhotoAlbum, context: persistenceCtrl.context)
        photoAlbum.travelLocation = travelLocation

        var photos = [Photo]()
        for transPhoto in transPhotos{
            let photo = TransientPersistentConversionBridge.toPhoto(transPhoto, context: persistenceCtrl.context)
            photo.photoAlbum = photoAlbum
            photos.append(photo)
        }

        persistenceCtrl.saveContext()
    }
    
    // Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier{
            if identifier == Identifiers.Segues.EmbedCollectionViewController{
                collectionViewController = segue.destination as! PhotoCollectionViewViewController
            }
        }
    }
}

// MARK: UI helper methods

extension PhotoAlbumViewController{

    fileprivate func configureUI(enabled: Bool){
        newCollectionButton.isEnabled = enabled
    }
    
    fileprivate func configureContainerViewLayout() {
        let shouldHideCollectionViewContainerView = (transPhotoAlbum != nil && transPhotos.count == 0)
        collectionViewContainerView.isHidden = shouldHideCollectionViewContainerView
        noImagesContainerView.isHidden = !shouldHideCollectionViewContainerView
    }
}

// MARK: PhotoCollectionViewViewController delegate

extension PhotoAlbumViewController: PhotoCollectionViewViewControllerDelegate{

    func didRemovePhotoAt(_ indexPath: IndexPath) {
        self.transPhotos.remove(at: indexPath.row)
        self.persistChanges()
    }
}

