//
//  ImgurStarterTests.swift
//  ImgurStarterTests
//
//  Created by Stuart Levine on 5/25/18.
//  Copyright © 2018 Wildcat Productions. All rights reserved.
//

import XCTest
@testable import ImgurStarter

class ImgurStarterTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    ////
    // Test the decoding of an ImgurImage object from the image JSON response
    // for when we load the image list from the api
    //
    func testImgurImage() {
        let imgurImageJSON: String = """
         {
            \"id\": \"orunSTu\",
            \"title\": \"Mickey Mouse\",
            \"description\": \"An image of the famous mouse.\",
            \"datetime\": 1495556889,
            \"type\": \"image/gif\",
            \"animated\": false,
            \"width\": 1,
            \"height\": 1,
            \"size\": 42,
            \"views\": 0,
            \"bandwidth\": 0,
            \"vote\": null,
            \"favorite\": true,
            \"nsfw\": null,
            \"section\": null,
            \"account_url\": null,
            \"account_id\": 0,
            \"is_ad\": false,
            \"in_most_viral\": false,
            \"tags\": [],
            \"ad_type\": 0,
            \"ad_url\": \"\",
            \"in_gallery\": false,
            \"deletehash\": \"x70po4w7BVvSUzZ\",
            \"name\": \"Mickey!\",
            \"link\": \"http://i.imgur.com/orunSTu.gif\"
          }
        """
        let jsonData = imgurImageJSON.data(using: .utf8)
        XCTAssertNotNil(jsonData)

        let photo = try? JSONDecoder().decode(ImgurImage.self, from: jsonData!)
        XCTAssertNotNil(photo)
        // Check properties match the JSON we received
        XCTAssertEqual(photo?.imageId, "orunSTu")
        XCTAssertEqual(photo?.link, "http://i.imgur.com/orunSTu.gif")
        XCTAssertEqual(photo?.title, "Mickey Mouse")
        XCTAssertEqual(photo?.name, "Mickey!")
        if let datetime = Int64("1495556889") {
            let date = Date(timeIntervalSince1970: TimeInterval(integerLiteral: datetime))
            XCTAssertEqual(photo?.datetime, date)
        }
        else {
            XCTFail()
        }
        XCTAssertEqual(photo?.description, "An image of the famous mouse.")
        XCTAssertEqual(photo?.type, "image/gif")
        XCTAssertEqual(photo?.favorite, true)
        XCTAssertEqual(photo?.height, 1)
        XCTAssertEqual(photo?.width, 1)
        XCTAssertEqual(photo?.size, 42)
        XCTAssertEqual(photo?.views, 0)
        XCTAssertEqual(photo?.deleteHash, "x70po4w7BVvSUzZ")
    }

    ////
    // Test encoding fo the PhotoUpload object for use when uploading an image to the Imgur API
    //
    func testPhotoUpload() {
        guard let image = UIImage(named: "greencirclecheckmark") else {
            XCTFail("could not find greencirclecheckmark image")
            return
        }

        let photoUpload = PhotoUpload(photo: image, title: "Green Circle Check Mark", name: "Check it out!", description: "An icon for testing yo!")
        let json = try? JSONEncoder().encode(photoUpload)
        XCTAssertNotNil(json)
        let jsonDict = (try? JSONSerialization.jsonObject(with: json!, options: [])) as? [String: Any]
        XCTAssertNotNil(jsonDict)
        XCTAssertEqual(photoUpload.image, jsonDict!["image"] as? String)
        XCTAssertEqual(photoUpload.name, jsonDict!["name"] as? String )
        XCTAssertEqual(photoUpload.title, jsonDict!["title"] as? String)
        XCTAssertEqual(photoUpload.description, jsonDict!["description"] as? String)
        XCTAssertEqual(photoUpload.type, jsonDict!["type"] as? String)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
