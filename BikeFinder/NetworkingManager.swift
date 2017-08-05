//
//  NetworkingManager.swift
//  BikeFinder
//
//  Created by Candance Smith on 8/5/17.
//  Copyright © 2017 Candance Smith. All rights reserved.
//

import UIKit

class NetworkingManager: NSObject {
    
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
                    self?.saveFeedURLs(jsonObject: json)
                }
            } catch let error {
                print("JSONSerialization Error: " + error.localizedDescription)
            }
            
            self?.dataTask = nil
        }
        
        // Start the dataTask
        dataTask?.resume()
    }
    
    private func saveFeedURLs(jsonObject: [String: AnyObject]) {
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
    }
}
