//
//  MapViewController.swift
//  BikeFinder
//
//  Created by Candance Smith on 8/5/17.
//  Copyright © 2017 Candance Smith. All rights reserved.
//

import UIKit
import Mapbox
import RealmSwift

class MapViewController: UIViewController, MGLMapViewDelegate {

    // MARK: - Outlets and Variables
    
    @IBOutlet weak var mapView: MGLMapView!
    
    private var bikeStations: Results<BikeStation>?
    private var pointAnnotations = [MGLPointAnnotation]()
    
    // MARK: - Set Up View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.userTrackingMode = .follow
        
        fetchBikeStations()
        pointAnnotations = annotateBikeStationsOnMap()
        mapView.addAnnotations(pointAnnotations)
    }
    
    private func fetchBikeStations() {
        do {
            let realm = try Realm()
            bikeStations = realm.objects(BikeStation.self)
        } catch let error {
            print("Bike Stations Fetch Error: " + error.localizedDescription)
        }
    }
    
    private func annotateBikeStationsOnMap() -> [MGLPointAnnotation] {
        var pointAnnotations = [MGLPointAnnotation]()
        if let bikeStations = bikeStations {
            for bikeStation in bikeStations {
                let point = MGLPointAnnotation()
                point.coordinate = CLLocationCoordinate2DMake(bikeStation.lat, bikeStation.lon)
                point.title = bikeStation.name
                pointAnnotations.append(point)
            }
        }
        return pointAnnotations
    }
}


