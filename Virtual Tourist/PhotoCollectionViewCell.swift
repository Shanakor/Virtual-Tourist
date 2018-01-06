//
//  PhotoCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Niklas Rammerstorfer on 06.01.18.
//  Copyright © 2018 Niklas Rammerstorfer. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {

    // MARK: IBOutlets

    @IBOutlet weak var imageView: UIImageView!

    // MARK: Initialization

    func setup(with photo:Photo){
        imageView.image = UIImage(data: photo.imageData as! Data)
    }
}
