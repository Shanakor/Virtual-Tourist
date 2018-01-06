//
// Created by Niklas Rammerstorfer on 06.01.18.
// Copyright (c) 2018 Niklas Rammerstorfer. All rights reserved.
//

import Foundation

extension Photo{
    func toTransient() -> TransientPhoto{
        return TransientPhoto(url: url, imageData: imageData)
    }

    static func convertArrayToTransient(_ array: [Photo]) -> [TransientPhoto]{
        var transPhotos = [TransientPhoto]()

        for photo in array{
            transPhotos.append(photo.toTransient())
        }

        return transPhotos
    }
}