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
    @IBOutlet weak var metadataContainerView: UIView!
    
    // MARK: Constants

    fileprivate struct Identifiers{
        struct Segues{
            static let EmbedCollectionViewController = "EmbedCollectionViewController"
        }
    }

    // MARK: Properties

    var annotation: MKAnnotation!
    var travelLocation: TravelLocation!

    private let coreDataStackFacade = CoreDataStackFacade.shared

    private var transTravelLocation: TransientTravelLocation!
    private var transPhotoAlbum: TransientPhotoAlbum!
    private var transPhotos = [TransientPhoto](){
        didSet {
            collectionViewController.transPhotos = transPhotos

            if transPhotos.count == 0{
                configureContainerViewsVisibility()
            }
        }
    }

    private var isFetchingMetadataInProgress = false
    private var collectionViewController: PhotoCollectionViewViewController!

    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.travelLocation = coreDataStackFacade.fetchTravelLocationAsync(lat: annotation.coordinate.latitude, lon: annotation.coordinate.longitude)
        initTransientProperties()

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

        configureContainerViewsVisibility()

        mapView.addAnnotation(annotation)
        mapView.showAnnotations([annotation], animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if self.transPhotoAlbum == nil{
            startPhotoAlbumDownloadRoutine()
        }
        else{
            let emptyTransPhotos = transPhotos.filter({$0.imageData == nil})

            if emptyTransPhotos.count > 0{
                startPhotoDownloadRoutine(photos: emptyTransPhotos)
            }
        }
    }

    private func startPhotoAlbumDownloadRoutine() {
        isFetchingMetadataInProgress = true
        configureContainerViewsVisibility()
        enableUI(false)

        downloadPhotoAlbum() {
            DispatchQueue.main.async {
                self.enableUI(true)
                self.persistChanges()
            }
        }
    }

    private func startPhotoDownloadRoutine(photos: [TransientPhoto]){
        enableUI(false)

        downloadPhotoData(of: photos){
            DispatchQueue.main.async {
                self.enableUI(true)
                self.persistChanges()
            }
        }
    }

    // MARK: IBActions
    
    @IBAction func downloadNewPage(_ sender: Any) {
        self.transPhotos = [TransientPhoto]()

        transPhotoAlbum.page = transPhotoAlbum.page + 1
        if transPhotoAlbum.page > transPhotoAlbum.pageCount!{
            transPhotoAlbum.page = 1
        }

        startPhotoAlbumDownloadRoutine()
    }
    
    // MARK: Network Requests

    private func downloadPhotoAlbum(completionHandler: @escaping () -> Void) {

        // PhotoAlbum metadata.

        FlickrAPIClient.shared.getPhotoMetadata(for: transTravelLocation, page: (transPhotoAlbum == nil ? 1 : transPhotoAlbum!.page)){
            transPhotoAlbum, transPhotos, error in

            guard error == nil else{
                self.presentAlertDialog(for: error!)
                return
            }

            self.transPhotoAlbum = transPhotoAlbum
            self.transPhotos = transPhotos!

            DispatchQueue.main.async{
                self.isFetchingMetadataInProgress = false
                // Show image label if no photos were found.
                self.configureContainerViewsVisibility()
            }

            self.downloadPhotoData(of: transPhotos!, completionHandler: completionHandler)
        }
    }

    private func downloadPhotoData(of transientPhotos: [TransientPhoto], completionHandler: @escaping () -> Void) {

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

                    self.persistChanges()
                },
                completionHandler: {
                    error in

                    if error != nil {
                        self.presentAlertDialog(for: error!)
                    }

                    completionHandler()
                })
    }

    // MARK: Persistence

    private func persistChanges() {
        coreDataStackFacade.performBackgroundBatchOperation{
            context in

            if let photoAlbum = self.travelLocation.photoAlbum{
                // Due to delete rule cascade, all photos get deleted also.
                context.delete(photoAlbum)
            }

            let photoAlbum = TransientPersistentConversionBridge.toPhotoAlbum(self.transPhotoAlbum, context: context)
            photoAlbum.travelLocation = self.travelLocation

            var photos = [Photo]()
            for transPhoto in self.transPhotos{
                let photo = TransientPersistentConversionBridge.toPhoto(transPhoto, context: context)
                photo.photoAlbum = photoAlbum
                photos.append(photo)
            }

            self.coreDataStackFacade.saveBackgroundContext()
        }
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

// MARK: UI Helper Methods

extension PhotoAlbumViewController{

    fileprivate func enableUI(_ enabled: Bool){
        newCollectionButton.isEnabled = enabled
    }
    
    fileprivate func configureContainerViewsVisibility() {
        metadataContainerView.isHidden = !isFetchingMetadataInProgress

        let shouldHideCollectionViewContainerView = (transPhotoAlbum != nil && transPhotos.count == 0)
        collectionViewContainerView.isHidden = shouldHideCollectionViewContainerView
        noImagesContainerView.isHidden = (isFetchingMetadataInProgress || !shouldHideCollectionViewContainerView)
    }

    // MARK: Presenting errors

    fileprivate func presentAlertDialog(for error: FlickrAPIClient.APIClientError) {
        switch(error){
        case .connectionError:
            self.presentAlertDialog(title: ErrorMessageConstants.AlertDialogStrings.ConnectionError.Title, message: ErrorMessageConstants.AlertDialogStrings.ConnectionError.Message)
        case .parseError:
            self.presentAlertDialog(title: ErrorMessageConstants.AlertDialogStrings.ParseError.Title, message: ErrorMessageConstants.AlertDialogStrings.ParseError.Message)
        case .serverError:
            self.presentAlertDialog(title: ErrorMessageConstants.AlertDialogStrings.CredentialError.Title, message: ErrorMessageConstants.AlertDialogStrings.CredentialError.Message)
        default:
            break
        }
    }

    fileprivate func presentAlertDialog(title: String, message: String){
        let alertCtrl = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alertCtrl.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))

        self.present(alertCtrl, animated: true, completion: nil)
    }
}

// MARK: PhotoCollectionViewViewController Delegate

extension PhotoAlbumViewController: PhotoCollectionViewViewControllerDelegate{

    func didRemovePhoto(at indexPath: IndexPath) {
        self.transPhotos.remove(at: indexPath.row)
        self.persistChanges()
    }
}

