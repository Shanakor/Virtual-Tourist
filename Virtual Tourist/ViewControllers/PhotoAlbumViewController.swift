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
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    // MARK: Constants

    fileprivate struct Identifiers{
        static let PhotoCell = "PhotoCell"
    }

    private let maxItemsInRow: CGFloat = 3
    private let minimumSpacing: CGFloat = 2

    // MARK: Properties

    var annotation: MKAnnotation!
    var travelLocation: TravelLocation!

    let persistenceCtrl = PersistenceController.shared

    var transTravelLocation: TransientTravelLocation!
    var transPhotoAlbum: TransientPhotoAlbum!
    var transPhotos = [TransientPhoto](){
        didSet {
            collectionView.reloadData()
        }
    }


    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.travelLocation = persistenceCtrl.fetchTravelLocation(lat: annotation.coordinate.latitude, lon: annotation.coordinate.longitude)

        initTransientProperties()
        configureCollectionView()
    }

    private func initTransientProperties() {
        transTravelLocation = TransientTravelLocation(latitude: travelLocation.latitude, longitude: travelLocation.longitude)

        guard let photoAlbum = travelLocation.photoAlbum else{
            return
        }

        transPhotoAlbum = TransientPhotoAlbum(page: photoAlbum.page, pageCount: photoAlbum.pageCount)

        if let photos = photoAlbum.photos{
            transPhotos = Photo.convertArrayToTransient(photos.allObjects as! [Photo])
        }
    }

    private func configureCollectionView() {
        self.collectionView.dataSource = self

        configureCollectionViewFlowLayout()
    }

    private func configureCollectionViewFlowLayout(){
        flowLayout.minimumInteritemSpacing = minimumSpacing
        flowLayout.minimumLineSpacing = minimumSpacing

        let dimension = (view.frame.width - 2 * minimumSpacing) / maxItemsInRow
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
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
                    self.persistPhotoAlbum()
                }
            }
        }
    }

    // MARK: Network Requests
    // TODO: Replace print(error) everywhere with UIAlertDialogs.

    private func persistPhotoAlbum() {
        if let photoAlbum = travelLocation.photoAlbum{
            // Due to delete rule cascade, all photos get deleted also.
            persistenceCtrl.context.delete(photoAlbum)
        }

        let photoAlbum = PhotoAlbum(page: transPhotoAlbum.page, pageCount: transPhotoAlbum.pageCount!, context: persistenceCtrl.context)
        photoAlbum.travelLocation = travelLocation

        var photos = [Photo]()
        for transPhoto in transPhotos{
            let photo = Photo(url: transPhoto.url!, imageData: transPhoto.imageData, context: persistenceCtrl.context)
            photo.photoAlbum = photoAlbum
            photos.append(photo)
        }

        persistenceCtrl.saveContext()
    }

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
}

// MARK: UI helper methods

extension PhotoAlbumViewController{

    fileprivate func configureUI(enabled: Bool){
        newCollectionButton.isEnabled = enabled
    }
}

// MARK: UICollectionView DataSource

extension PhotoAlbumViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return transPhotos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photo = transPhotos[indexPath.row]

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifiers.PhotoCell, for: indexPath) as! PhotoCollectionViewCell

        cell.setup(with: photo)
        
        return cell
    }
}
