//
//  BikeFinderTests.swift
//  BikeFinderTests
//
//  Created by Candance Smith on 8/5/17.
//  Copyright © 2017 Candance Smith. All rights reserved.
//

import XCTest
import Mockingjay
import RealmSwift
import BikeFinder

@testable import BikeFinder

class BikeFinderTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        deleteTestObject()
    }
    
    override func tearDown() {
        super.tearDown()
        deleteTestObject()
    }
    
    func deleteTestObject() {
        // Make sure our test object doesn't already exist in realm
        guard let realm = try? Realm() else { return }
        try? realm.write {
            if let testStation = realm.object(ofType: BikeStation.self, forPrimaryKey: "duck") {
                realm.delete(testStation)
            }
        }
    }
    
    func testGetStationStatusFeed() {
        // Verify we have all the resources we need for the test before starting
        let testBundle = Bundle(for: type(of: self))
        guard let file = testBundle.url(forResource: "StationStatusFeedResponse",
                                        withExtension: "json",
                                        subdirectory: "MockJSON",
                                        localization: nil),
        let data = try? Data(contentsOf: file),
        let realm = try? Realm() else { XCTFail(); return }
        
        // Create a test object to be updated by getStationStatusFeed
        // Everything on the object should be in its blank state
        try? realm.write {
            let newBikeStation = BikeStation()
            newBikeStation.stationID = "duck"
            XCTAssertEqual(newBikeStation.availableBikes, 0)
            XCTAssertEqual(newBikeStation.availableDocks, 0)
            XCTAssertFalse(newBikeStation.isInstalled)
            XCTAssertFalse(newBikeStation.isRenting)
            XCTAssertFalse(newBikeStation.isReturning)
            realm.add(newBikeStation)
        }
        
        // Mock the network call
        stub(uri("https://gbfs.citibikenyc.com/gbfs/en/station_status.json"), jsonData(data))

        let expectation = XCTestExpectation(description: "network parsing")
        
        NetworkingManager.shared.getStationStatusFeed(completion: { (success) in
            guard success == true else { XCTFail(); return }
            DispatchQueue.main.async {
                // Verify that the testObject was updated with our mock JSON response
                if let bikeStation = realm.object(ofType: BikeStation.self, forPrimaryKey: "duck") {
                    XCTAssertEqual(bikeStation.availableBikes, 3)
                    XCTAssertEqual(bikeStation.availableDocks, 36)
                    XCTAssertTrue(bikeStation.isInstalled)
                    XCTAssertTrue(bikeStation.isRenting)
                    XCTAssertTrue(bikeStation.isReturning)
                } else {
                    XCTFail()
                }
                expectation.fulfill()
            }
        })
        // Wait for expectation to be fulfilled or 6 seconds
        // Async might not return immediately
        wait(for: [expectation], timeout: 6)
    }
}
