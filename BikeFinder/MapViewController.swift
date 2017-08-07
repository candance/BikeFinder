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

    // MARK: - MGLMapViewDelegate
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        guard annotation is MGLPointAnnotation else {
            return nil
        }
        
        // Reuse existing annotations to improve performance
        let reuseIdentifier = "\(annotation.coordinate.longitude)"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        
        // Initialize a new annotation view if none available
        if annotationView == nil {
            annotationView = CustomAnnotationView(reuseIdentifier: reuseIdentifier)
            annotationView!.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            
            // TODO: Annotation view color matches bike station operating status
            annotationView!.backgroundColor = UIColor.red
        }
        return annotationView
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {
        mapView.setCenter(annotation.coordinate, animated: true)
    }
}

// MARK: - MGLAnnotationView subclass
class CustomAnnotationView: MGLAnnotationView {
    override func layoutSubviews() {
        super.layoutSubviews()

        // Turn annotation view into circle
        layer.cornerRadius = frame.width / 2
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.cgColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Thicker border if annotation view is selected
        layer.borderWidth = selected ? 4 : 2
    }
}


