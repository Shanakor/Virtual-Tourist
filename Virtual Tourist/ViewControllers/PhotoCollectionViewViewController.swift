//
//  PhotoCollectionViewViewController.swift
//  Virtual Tourist
//
//  Created by Niklas Rammerstorfer on 06.01.18.
//  Copyright © 2018 Niklas Rammerstorfer. All rights reserved.
//

import UIKit

class PhotoCollectionViewViewController: UIViewController {

    // MARK: IBOutlets
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!

    // MARK: Constants

    fileprivate struct Identifiers{
        static let PhotoCell = "PhotoCell"
        static let LoadingPhotoCell = "LoadingPhotoCell"
    }

    private let maxItemsInRow: CGFloat = 3
    private let minimumSpacing: CGFloat = 2

    // MARK: Properties

    var transPhotos = [TransientPhoto](){
        didSet{
            DispatchQueue.main.async{
                self.collectionView.reloadData()
            }
        }
    }
    var delegate: PhotoCollectionViewViewControllerDelegate?

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureCollectionView()
    }

    private func configureCollectionView() {
        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        configureCollectionViewFlowLayout()
    }

    private func configureCollectionViewFlowLayout() {
        flowLayout.minimumInteritemSpacing = minimumSpacing
        flowLayout.minimumLineSpacing = minimumSpacing

        let dimension = (view.frame.width - 2 * minimumSpacing) / maxItemsInRow
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
}

// MARK: UICollectionView DataSource and Delegate

extension PhotoCollectionViewViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    // MARK: DataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return transPhotos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photo = transPhotos[indexPath.row]

        if photo.imageData != nil {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifiers.PhotoCell, for: indexPath) as! PhotoCollectionViewCell
            cell.setup(with: photo)

            return cell
        }
        else{
            return collectionView.dequeueReusableCell(withReuseIdentifier: Identifiers.LoadingPhotoCell, for: indexPath)
        }
    }

    // MARK: Delegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell != nil {
            self.transPhotos.remove(at: indexPath.row)
            self.collectionView.reloadData()

            delegate?.didRemovePhoto(at: indexPath)
        }
    }
}
