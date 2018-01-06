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

    let persistenceCtrl = PersistenceController.shared

    var transientPhotos: [TransientPhoto]?
    var travelLocation: TravelLocation!
    var photoAlbum: PhotoAlbum?
    var photos = [Photo](){
        didSet {
            collectionView.reloadData()
        }
    }

    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureCollectionView()
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

        self.travelLocation = persistenceCtrl.fetchTravelLocation(lat: annotation.coordinate.latitude, lon: annotation.coordinate.longitude)

        mapView.addAnnotation(annotation)
        mapView.showAnnotations([annotation], animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        configureUI(enabled: false)

        downloadPhotoAlbum(){
            DispatchQueue.main.async {
                self.configureUI(enabled: true)
                self.persistPhotoAlbum()
            }
        }
    }

    // MARK: Network Requests
    // TODO: Replace print(error) everywhere with UIAlertDialogs.

    private func persistPhotoAlbum() {
        persistenceCtrl.saveContext()
    }

    private func downloadPhotoAlbum(completionHandler: @escaping () -> Void) {

        // PhotoAlbum metadata.

        let travelLocation = TransientTravelLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)

        FlickrAPIClient.shared.getPhotoAlbumMetadata(travelLocation: travelLocation,
                photoAlbum: nil){
            transientPhotoAlbum, transientPhotos, error in

            guard error == nil else{
                print(error!)
                return
            }

            if let photoAlbum = self.travelLocation.photoAlbum{
                self.photoAlbum = photoAlbum
                self.photoAlbum!.page = Int32(transientPhotoAlbum!.page)
                self.photoAlbum!.pageCount = Int32(transientPhotoAlbum!.pageCount)
            }
            else{
                self.photoAlbum = PhotoAlbum(page: transientPhotoAlbum!.page, pageCount: transientPhotoAlbum!.pageCount,
                        context: self.persistenceCtrl.context)
                self.photoAlbum!.travelLocation = self.travelLocation
            }

            self.transientPhotos = transientPhotos

            self.loadPhotoData(){
                completionHandler()
            }
        }
    }

    private func loadPhotoData(completionHandler: @escaping () -> Void) {

        FlickrAPIClient.shared.downloadPhotoData(self.transientPhotos!,
                progressHandler: {
                    transientPhoto, error in

                    guard error == nil else{
                        print(error!)
                        return
                    }

                    let photo = Photo(url: transientPhoto.url, imageData: transientPhoto.imageData!,
                            context: self.persistenceCtrl.context)
                    photo.photoAlbum = self.photoAlbum

                    DispatchQueue.main.async {
                        self.photos.append(photo)
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
        return photos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifiers.PhotoCell, for: indexPath) as! PhotoCollectionViewCell
        let photo = photos[indexPath.row]
        
        cell.setup(with: photo)
        
        return cell
    }
}
