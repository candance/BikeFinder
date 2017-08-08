//
//  BikeStation.swift
//  BikeFinder
//
//  Created by Candance Smith on 8/5/17.
//  Copyright © 2017 Candance Smith. All rights reserved.
//

import Foundation
import RealmSwift

public class BikeStation: Object {
    public dynamic var stationID = ""
    public dynamic var name = ""
    public dynamic var lat = 0.0
    public dynamic var lon = 0.0
    public dynamic var capacity = 0
    public dynamic var availableBikes = 0
    public dynamic var availableDocks = 0
    public dynamic var isInstalled = false
    public dynamic var isRenting = false
    public dynamic var isReturning = false
    
    override public static func primaryKey() -> String? {
        return "stationID"
    }
}
