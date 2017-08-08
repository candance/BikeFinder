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
    
    override func tearDown() {
        
    }
    
    func testGetStationStatusFeed() {
        
        let testBundle = Bundle(for: type(of: self))
        guard let file = testBundle.url(forResource: "StationStatusFeedResponse",
                                        withExtension: "json",
                                        subdirectory: "MockJSON",
                                        localization: nil),
        let data = try? Data(contentsOf: file) else { XCTFail(); return }
        
        stub(uri("https://gbfs.citibikenyc.com/gbfs/en/station_status.json"), jsonData(data))
//        stub(uri("https://gbfs.citibikenyc.com/gbfs/en/station_status.json"), failure(NSError(domain: "", code: 404, userInfo: nil)))

        let expectation = XCTestExpectation(description: "network parsing")

        NetworkingManager.shared.getStationStatusFeed(completion: { (success) in
            guard success == true else { XCTFail(); return }
            let realm = try! Realm()
            Thread.sleep(forTimeInterval: 3)
            if let station1 = realm.object(ofType: BikeStation.self, forPrimaryKey: "bunny") {
                XCTAssertEqual(station1.availableBikes, 31)
                XCTAssertEqual(station1.availableDocks, 18)
                XCTAssertTrue(!station1.isInstalled)
                XCTAssertTrue(!station1.isRenting)
                XCTAssertTrue(!station1.isReturning)
            } else {
                XCTFail()
            }
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: 10)
    }
    
}
