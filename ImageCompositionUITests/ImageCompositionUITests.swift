//
//  ImageCompositionUITests.swift
//  ImageCompositionUITests
//
//  Created by Jae Kyung Lee on 2020/03/18.
//  Copyright © 2020 Jae Kyung Lee. All rights reserved.
//

import XCTest

class ImageCompositionUITests: XCTestCase {
    
    let app = XCUIApplication()
    

    override func setUp() {
        continueAfterFailure = false
        app.launch()
    }

    override func tearDown() {
    }

    func testShare() {
        let photoCell = app.collectionViews.element(boundBy: 0).firstMatch
        photoCell.tap()
        let saveButton = app.navigationBars.buttons["Share"]
        saveButton.tap()
        
        let exp = expectation(description: "save combine result 2 photo library")
        let result = XCTWaiter.wait(for: [exp], timeout: 1)
        if result == XCTWaiter.Result.timedOut {
            XCTAssertTrue(app.buttons["Albums"].exists)
        } else {
           XCTFail("fail")
        }
    }

    func testLaunchPerformance() {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
                XCUIApplication().launch()
            }
        }
    }
}
