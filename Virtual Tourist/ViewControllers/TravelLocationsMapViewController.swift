//
//  TravelLocationsMapViewController.swift
//  Virtual Tourist
//
//  Created by Niklas Rammerstorfer on 04.01.18.
//  Copyright © 2018 Niklas Rammerstorfer. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController {

    // MARK: IBOutlets
    
    @IBOutlet weak var mapView: MKMapView!

    // MARK: Properties

    private var coreDataStackFacade = CoreDataStackFacade.shared

    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureMapView()
    }

    private func configureMapView() {
        mapView.delegate = self

        let gestureRecognizer = initLongPressGestureRecognizer()
        mapView.addGestureRecognizer(gestureRecognizer)

        let travelLocations = coreDataStackFacade.fetchAllTravelLocationsAsync()
        mapView.addAnnotations(TravelLocation.convertArrayToMKPointAnnotations(travelLocations))
    }

    private func initLongPressGestureRecognizer() -> UILongPressGestureRecognizer {
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        recognizer.minimumPressDuration = 0.5

        return recognizer
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        restoreMapRegionFromUserDefaults()

        // Hide navigation bar on first UIViewController.
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func restoreMapRegionFromUserDefaults() {
        if let centerLatitude = UserDefaults.standard.object(forKey: AppDelegate.UserDefaultsConstants.MapRegion.CenterLatitude),
           let centerLongitude = UserDefaults.standard.object(forKey: AppDelegate.UserDefaultsConstants.MapRegion.CenterLongitude),
           let spanLatitudeDelta = UserDefaults.standard.object(forKey: AppDelegate.UserDefaultsConstants.MapRegion.SpanLatitudeDelta),
           let spanLongitudeDelta = UserDefaults.standard.object(forKey: AppDelegate.UserDefaultsConstants.MapRegion.SpanLongitudeDelta){

            guard let centerLatitudeValue = centerLatitude as? Double else{
                print("The persisted value at key '\(AppDelegate.UserDefaultsConstants.MapRegion.CenterLatitude)' was not of type Double.")
                return
            }

            guard let centerLongitudeValue = centerLongitude as? Double else{
                print("The persisted value at key '\(AppDelegate.UserDefaultsConstants.MapRegion.CenterLongitude)' was not of type Double.")
                return
            }

            guard let spanLatitudeDeltaValue = spanLatitudeDelta as? Double else{
                print("The persisted value at key '\(AppDelegate.UserDefaultsConstants.MapRegion.CenterLatitude)' was not of type Double.")
                return
            }

            guard let spanLongitudeDeltaValue = spanLongitudeDelta as? Double else{
                print("The persisted value at key '\(AppDelegate.UserDefaultsConstants.MapRegion.CenterLongitude)' was not of type Double.")
                return
            }

            let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: centerLatitudeValue, longitude: centerLongitudeValue),
                    span: MKCoordinateSpan(latitudeDelta: spanLatitudeDeltaValue, longitudeDelta: spanLongitudeDeltaValue))

            mapView.setRegion(region, animated: false)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Show navigation bar for other UIViewControllers.
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }

    // MARK: Gesture Recognizers

    @objc private func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer){
        if gestureRecognizer.state != .began{
            return
        }

        let touchPoint = gestureRecognizer.location(in: self.mapView)
        let touchMapCoordinate = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)

        addPointAnnotationToMapViewAt(coordinate: touchMapCoordinate)
        persistTravelLocation(coordinate: touchMapCoordinate)
    }

    private func persistTravelLocation(coordinate: CLLocationCoordinate2D) {
        coreDataStackFacade.performBackgroundBatchOperation{
            context in

            let _ = TravelLocation(latitude: coordinate.latitude, longitude: coordinate.longitude, context: context)
            self.coreDataStackFacade.saveBackgroundContext()
        }
    }

    private func addPointAnnotationToMapViewAt(coordinate: CLLocationCoordinate2D) {
        let pointAnnotation = MKPointAnnotation()
        pointAnnotation.coordinate = coordinate

        if !self.mapView.annotations.contains(where:
            {other in
                pointAnnotation.coordinate.latitude == other.coordinate.latitude &&
                pointAnnotation.coordinate.longitude == other.coordinate.longitude
        }){
            self.mapView.addAnnotation(pointAnnotation)
        }
    }

    // MARK: Navigation

    fileprivate func showPhotoAlbumScene(){
        performSegue(withIdentifier: AppDelegate.SegueIdentifiers.PhotoAlbum, sender: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier{
            if identifier == AppDelegate.SegueIdentifiers.PhotoAlbum{
                let destCtrl = segue.destination as! PhotoAlbumViewController

                let selectedAnnotation = mapView.selectedAnnotations[0]
                destCtrl.annotation = selectedAnnotation
            }
        }
    }
}

// MARK: MKMapView Delegate

extension TravelLocationsMapViewController: MKMapViewDelegate{

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        persistMapRegion(mapView.region)
    }

    private func persistMapRegion(_ region: MKCoordinateRegion){
        UserDefaults.standard.set(region.center.latitude, forKey: AppDelegate.UserDefaultsConstants.MapRegion.CenterLatitude)
        UserDefaults.standard.set(region.center.longitude, forKey: AppDelegate.UserDefaultsConstants.MapRegion.CenterLongitude)
        UserDefaults.standard.set(region.span.latitudeDelta, forKey: AppDelegate.UserDefaultsConstants.MapRegion.SpanLatitudeDelta)
        UserDefaults.standard.set(region.span.longitudeDelta, forKey: AppDelegate.UserDefaultsConstants.MapRegion.SpanLongitudeDelta)
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        showPhotoAlbumScene()
    }
}

