//
// Created by Niklas Rammerstorfer on 05.01.18.
// Copyright (c) 2018 Niklas Rammerstorfer. All rights reserved.
//

import MapKit

extension TravelLocation{

    func toMKPointAnnotation() -> MKPointAnnotation{
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        return annotation
    }

    static func convertArrayToMKPointAnnotations(_ array: [TravelLocation]) -> [MKPointAnnotation]{
        var annotations = [MKPointAnnotation]()

        for location in array{
            annotations.append(location.toMKPointAnnotation())
        }

        return annotations
    }
}