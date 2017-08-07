//
//  NetworkingManager.swift
//  BikeFinder
//
//  Created by Candance Smith on 8/5/17.
//  Copyright © 2017 Candance Smith. All rights reserved.
//

import UIKit
import RealmSwift

protocol NetworkingManagerDelegate {
    func updateBikeStationStatuses()
}

class NetworkingManager: NSObject {
    
    // MARK: - Variables
    
    var networkingManagerDelegate: NetworkingManagerDelegate?
    
    typealias BikeStationResult = ([String: AnyObject]) -> ()
    
    lazy var realm: Realm? = {
        do {
            return try Realm()
        } catch {
            return nil
        }
    }()
    
    // Singleton for NetworkingManager
    static let shared = NetworkingManager()
    
    // Feed names and URLs
    private let kStationInformationFeed = "station_information"
    private let kStationStatusFeed = "station_status"
    private var stationInformationFeedURL: String?
    private var stationStatusFeedURL: String?
    
    // Citi Bike Auto-Discovery URL
    private let kBikeshareFeedURL = "https://gbfs.citibikenyc.com/gbfs/gbfs.json"
    
    // Create an URLSession
    private let defaultSession = URLSession(configuration: .default)
    
    // URLSessionDataTask to declare HTTP GET request to bikeshare feed
    private var dataTask: URLSessionDataTask?

    
    // MARK: - Saving specific feeds from main URL
    
    func getBikeshareFeeds() {
        getFeedJSON(kBikeshareFeedURL) { [weak self] (result) in
            self?.saveFeedURLs(result)
        }
    }
    
    private func saveFeedURLs(_ jsonObject: [String: AnyObject]) {
        guard let data = jsonObject["data"] as? [String: AnyObject], let en = data["en"], let feeds = en["feeds"] as? [[String: AnyObject]] else {
            return
        }
        for feed in feeds {
            guard let feedName = feed["name"] as? String, let url = feed["url"] as? String else {
                continue
            }
            if feedName == kStationInformationFeed {
                stationInformationFeedURL = url
                
            } else if feedName == kStationStatusFeed {
                stationStatusFeedURL = url
                
            }
        }
        getStationFeeds()
    }
    
    private func getStationFeeds() {
        getFeedJSON(stationInformationFeedURL) { [weak self] (result) in
            self?.createOrUpdateBikeStations(result)
            
            self?.getStationStatusFeed { [weak self] (done) in
                if done {
                    DispatchQueue.main.async {
                        self?.networkingManagerDelegate?.updateBikeStationStatuses()
                    }
                }
            }
        }
    }
    
    
    // MARK: - Creating or updating bike stations from Station Information feed
    
    private func createOrUpdateBikeStations(_ jsonObject: [String: AnyObject]) {
        guard let data = jsonObject["data"] as? [String: AnyObject], let stations = data["stations"] as? [[String: AnyObject]] else {
            return
        }
        
        guard let realm = realm else { return }
        let bikeStations = realm.objects(BikeStation.self)
        
        if bikeStations.count == 0 {
            createBikeStations(stations)
        } else {
            updateBikeStations(stations)
        }
    }
    
    private func createBikeStations(_ stations: [[String: AnyObject]]) {
        do {
            guard let realm = realm else { return }
            try realm.write {
                for station in stations {
                    guard let stationID = station["station_id"] as? String, let name = station["name"] as? String, let lat = station["lat"] as? Double, let lon = station["lon"] as? Double, let capacity = station["capacity"] as? Int else {
                        continue
                    }
                    let newBikeStation = BikeStation()
                    newBikeStation.stationID = stationID
                    newBikeStation.name = name
                    newBikeStation.lat = lat
                    newBikeStation.lon = lon
                    newBikeStation.capacity = capacity
                    realm.add(newBikeStation)
                }
            }
        } catch let error {
            print("Bike Station Create Error: " + error.localizedDescription)
        }
    }
    
    private func updateBikeStations(_ stations: [[String: AnyObject]]) {
        do {
            guard let realm = realm else { return }
            try realm.write {
                for station in stations {
                    guard let stationID = station["station_id"] as? String, let name = station["name"] as? String, let lat = station["lat"] as? Double, let lon = station["lon"] as? Double, let capacity = station["capacity"] as? Int else {
                        continue
                    }
                    
                    if let existingBikeStation = realm.object(ofType: BikeStation.self, forPrimaryKey: stationID) {
                        existingBikeStation.name = name
                        existingBikeStation.lat = lat
                        existingBikeStation.lon = lon
                        existingBikeStation.capacity = capacity
                    } else {
                        let newBikeStation = BikeStation()
                        newBikeStation.stationID = stationID
                        newBikeStation.name = name
                        newBikeStation.lat = lat
                        newBikeStation.lon = lon
                        newBikeStation.capacity = capacity
                        realm.add(newBikeStation)
                    }
                }
            }
        } catch let error {
            print("Bike Station Update Error: " + error.localizedDescription)
        }
    }
    
    // MARK: - Updating bike station status from Station Status feed
    
    func getStationStatusFeed(completion: @escaping (_ success: Bool) -> Void) {
        getFeedJSON(stationStatusFeedURL) { [weak self] (result) in
            self?.updateBikeStationStatus(result)
            completion(true)
        }
    }
    
    private func updateBikeStationStatus(_ jsonObject: [String: AnyObject]) {
        guard let data = jsonObject["data"] as? [String: AnyObject], let stations = data["stations"] as? [[String: AnyObject]] else {
            return
        }
        
        do {
            let realm = try Realm()

            for station in stations {
                guard let stationID = station["station_id"] as? String, let availableBikes = station["num_bikes_available"] as? Int, let availableDocks = station["num_docks_available"] as? Int, let isInstalled = station["is_installed"] as? Bool, let isRenting = station["is_renting"] as? Bool, let isReturning = station["is_returning"] as? Bool else {
                    continue
                }

                try realm.write {
                    if let existingBikeStation = realm.object(ofType: BikeStation.self, forPrimaryKey: stationID) {
                        existingBikeStation.availableBikes = availableBikes
                        existingBikeStation.availableDocks = availableDocks
                        existingBikeStation.isInstalled = isInstalled
                        existingBikeStation.isRenting = isRenting
                        existingBikeStation.isReturning = isReturning
                    }
                }
            }
        } catch let error {
            print("Bike Station Status Update Error: " + error.localizedDescription)
        }
    }

    
    // MARK: - Helper: Get JSON from feed
    
    private func getFeedJSON(_ urlString: String?, completion: @escaping BikeStationResult) {
        // Cancel existing dataTask if there is one already
        dataTask?.cancel()
        
        guard let urlString = urlString else { return }
        guard let url = URL(string: urlString) else { return }
        
        // Creating Data Task with already existing URLSession
        dataTask = defaultSession.dataTask(with: url) { [weak self] (data, response, error) in
            
            if let error = error {
                print("Data Task Error: " + error.localizedDescription)
            }
            guard let data = data else { return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: [.mutableContainers]) as? [String: AnyObject] {
                    completion(json)
                }
            } catch let error {
                print("JSONSerialization Error: " + error.localizedDescription)
            }
            // Set dataTask to nil at the end
            self?.dataTask = nil
        }
        // Start the dataTask
        dataTask?.resume()
    }
}
