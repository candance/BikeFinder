//
//  BikeFinderUITests.swift
//  BikeFinderUITests
//
//  Created by Candance Smith on 8/5/17.
//  Copyright © 2017 Candance Smith. All rights reserved.
//

import XCTest

class BikeFinderUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testOpenAppAndTapStation() {
        // Unsure of how to mock location, this test is flaky.
        let app = XCUIApplication()
        app.otherElements["mainMap"].tap()
        app.buttons["W 37 St & 10 Ave"].tap()
        
        let mapButton = app.buttons["Map"]
        mapButton.tap()
        app.staticTexts["W 38 St & 8 Ave"].tap()
        mapButton.tap()
        app.staticTexts["Broadway & W 37 St"].tap()
    }
    
}
