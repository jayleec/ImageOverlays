//
//  ImageCompositionTests.swift
//  ImageCompositionTests
//
//  Created by Jae Kyung Lee on 2020/03/18.
//  Copyright © 2020 Jae Kyung Lee. All rights reserved.
//

import XCTest
@testable import ImageComposition

class ImageCompositionTests: XCTestCase {

    override func setUp() {
        
    }

    override func tearDown() {
    }

    func test() {
        let sampleVideoUrl = "file:///var/mobile/Media/DCIM/100APPLE/IMG_0154.MOV"
        
        let progressHandler: (Float) -> Void = { p in
            print(p)
        }
        VideoOverlays.shared.exportCombinedVideo(from: URL(fileURLWithPath: sampleVideoUrl), progress: progressHandler , completion: { url in
            guard let url = url else {
                XCTFail("get export video url fail")
                return
            }
            
            let exp = self.expectation(description: "get export video url")
            let result = XCTWaiter.wait(for: [exp], timeout: 1)
            if result == XCTWaiter.Result.timedOut {
                XCTAssertTrue(url.isFileURL)
            } else {
                XCTFail("get export video url fail")
            }
            
        })
    }

    func testPerformanceExample() {
        self.measure {
        }
    }

}
