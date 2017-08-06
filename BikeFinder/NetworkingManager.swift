//
//  NetworkingManager.swift
//  BikeFinder
//
//  Created by Candance Smith on 8/5/17.
//  Copyright © 2017 Candance Smith. All rights reserved.
//

import UIKit
import RealmSwift

class NetworkingManager: NSObject {
    
    // MARK: - Variables
    
    typealias BikeStationResult = ([String: AnyObject]) -> ()
    
    lazy var realm: Realm? = {
        do {
            return try Realm()
        } catch {
            return nil
        }
    }()
    
    private var bikeStations: Results<BikeStation>?

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
        
        // Cancel existing dataTask if there is one already
        dataTask?.cancel()
        
        guard let url = URL(string: kBikeshareFeedURL) else { return }
        
        // Creating Data Task with already existing URLSession
        dataTask = defaultSession.dataTask(with: url) { [weak self] (data, response, error) in
            
            if let error = error {
                print("Data Task Error: " + error.localizedDescription)
            }
            guard let data = data else { return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: [.mutableContainers]) as? [String: AnyObject] {
                    self?.saveFeedURLs(json)
                }
            } catch let error {
                print("JSONSerialization Error: " + error.localizedDescription)
            }
            
            self?.dataTask = nil
        }
        
        // Start the dataTask
        dataTask?.resume()
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
                
                getStationInformationFeed(url)
            } else if feedName == kStationStatusFeed {
                stationStatusFeedURL = url
                // TODO
            }
        }
    }
    
    
    // MARK: - Creating or updating bike stations from feeds
    
    private func getStationInformationFeed(_ url: String) {
        dataTask?.cancel()
        
        guard let url = URL(string: url) else { return }
        
        dataTask = defaultSession.dataTask(with: url) { [weak self] (data, response, error) in
            
            if let error = error {
                print("Data Task Error: " + error.localizedDescription)
            }
            guard let data = data else { return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: [.mutableContainers]) as? [String: AnyObject]{
                    self?.createOrUpdateBikeStations(json)
                }
            } catch let error {
                print("JSONSerialization Error: " + error.localizedDescription)
            }
            
            self?.dataTask = nil
        }
        
        // Start the dataTask
        dataTask?.resume()
    }
    
    private func createOrUpdateBikeStations(_ jsonObject: [String: AnyObject]) {
        guard let data = jsonObject["data"] as? [String: AnyObject], let stations = data["stations"] as? [[String: AnyObject]] else {
            return
        }
        
        guard let realm = realm else { return }
        bikeStations = realm.objects(BikeStation.self)
        
        if bikeStations?.count == 0 {
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
            bikeStations = realm.objects(BikeStation.self)
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
            bikeStations = realm.objects(BikeStation.self)
        } catch let error {
            print("Bike Station Update Error: " + error.localizedDescription)
        }
    }
}
