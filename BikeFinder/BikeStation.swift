//
//  BikeStation.swift
//  BikeFinder
//
//  Created by Candance Smith on 8/5/17.
//  Copyright © 2017 Candance Smith. All rights reserved.
//

import Foundation
import RealmSwift

class BikeStation: Object {
    dynamic var stationID = ""
    dynamic var name = ""
    dynamic var lat = 0.0
    dynamic var lon = 0.0
    dynamic var capacity = 0
    dynamic var availableBikes = 0
    dynamic var availableDocks = 0
    dynamic var isInstalled = false
    dynamic var isRenting = false
    dynamic var isReturning = false
    
    override static func primaryKey() -> String? {
        return "stationID"
    }
}
