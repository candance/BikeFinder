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

class MapViewController: UIViewController, MGLMapViewDelegate, NetworkingManagerDelegate {

    // MARK: - Outlets and Variables
    
    @IBOutlet weak var mapView: MGLMapView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    private var bikeStations: Results<BikeStation>?
    private var pointAnnotations = [MGLPointAnnotation]()
    
    // MARK: - Set Up View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NetworkingManager.shared.networkingManagerDelegate = self
        mapView.delegate = self
        
        mapView.userTrackingMode = .follow
                
        fetchBikeStations()
        pointAnnotations = annotateBikeStationsOnMap(segmentedControl.selectedSegmentIndex)
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
    
    private func annotateBikeStationsOnMap(_ bikeOrDockIndex: Int) -> [CustomPointAnnotation] {
        var pointAnnotations = [CustomPointAnnotation]()
        if let bikeStations = bikeStations {
            for bikeStation in bikeStations {
                let point = CustomPointAnnotation()
                point.coordinate = CLLocationCoordinate2DMake(bikeStation.lat, bikeStation.lon)
                point.title = bikeStation.name
                point.subtitle = "Bikes: " + String(bikeStation.availableBikes) + ", Docks: " + String(bikeStation.availableDocks)
                point.color = statusAnnotationColor(bikeStation, bikeOrDockIndex)
                pointAnnotations.append(point)
            }
        }
        return pointAnnotations
    }
  
    // MARK: - MGLMapViewDelegate
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        
        if let annotation = annotation as? CustomPointAnnotation, let color = annotation.color {
            
            // Reuse existing annotations to improve performance
            let reuseIdentifier = "\(annotation.coordinate.longitude)"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
            
            // Initialize a new annotation view if none available
            if annotationView == nil {
                annotationView = CustomAnnotationView(reuseIdentifier: reuseIdentifier)
                annotationView!.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
                
                // Annotation view color matches bike station operating status
                annotationView!.backgroundColor = color
            }
            return annotationView
        }
        return nil
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {
        mapView.setCenter(annotation.coordinate, animated: true)
    }
    
    
    // MARK: - Refresh Bike Station Status
    
    @IBAction func refreshButtonTouched(_ sender: Any) {
        NetworkingManager.shared.getStationStatusFeed { [weak self] (done) in
            if done {
                DispatchQueue.main.async {
                    self?.updateBikeStationStatuses()
                }
            }
        }
    }

    // Used in <NetworkingManagerDelegate> as well
    func updateBikeStationStatuses() {
        fetchBikeStations()
        mapView.removeAnnotations(pointAnnotations)
        pointAnnotations = annotateBikeStationsOnMap(segmentedControl.selectedSegmentIndex)
        mapView.addAnnotations(pointAnnotations)
    }
    
    // MARK: - Toggle Between Bike and Dock Mode

    @IBAction func segmentedControlTouched(_ sender: Any) {
        mapView.removeAnnotations(pointAnnotations)
        pointAnnotations = annotateBikeStationsOnMap(segmentedControl.selectedSegmentIndex)
        mapView.addAnnotations(pointAnnotations)
    }
    
    private func statusAnnotationColor(_ bikeStation: BikeStation, _ bikeOrDockIndex: Int) -> UIColor {
        let available = bikeOrDockIndex == 0 ? bikeStation.availableBikes : bikeStation.availableDocks
        if bikeStation.isInstalled == true, bikeStation.isReturning == true, bikeStation.isRenting == true {
            if available == 0 {
                return .red
            } else if available <= 3 {
                return .orange
            } else {
                return .green
            }
        }
        return .gray
    }
}

// MARK: - MGLAnnotationView subclass
class CustomPointAnnotation: MGLPointAnnotation {
    var color: UIColor?
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


