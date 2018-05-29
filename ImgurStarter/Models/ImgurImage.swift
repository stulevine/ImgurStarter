//
//  image.swift
//  ImgurStarter
//
//  Created by Stuart Levine on 5/26/18.
//  Copyright © 2018 Wildcat Productions. All rights reserved.
//

import Foundation
import UIKit

enum ImageDownloadState {
    case new, downloaded, downloading, failed
}

/* imgur iamge response json model
 {
 "account_id" = 13240936;
 "account_url" = stulevine;
 "ad_type" = 0;
 "ad_url" = "";
 animated = 0;
 bandwidth = 0;
 datetime = 1407177957;
 deletehash = ZHEecRaynf2RyWM;
 description = "<null>";
 favorite = 0;
 "has_sound" = 0;
 height = 3264;
 id = CroRnGz;
 "in_gallery" = 0;
 "in_most_viral" = 0;
 "is_ad" = 0;
 link = "https://i.imgur.com/CroRnGz.jpg";
 name = photo;
 nsfw = "<null>";
 section = "<null>";
 size = 542806;
 tags =     (
 );
 title = "<null>";
 type = "image/jpeg";
 views = 0;
 vote = "<null>";
 width = 2448;
 } */

// imgur image model
class ImgurImage: Codable, NetworkDataEngineProtocol {

    // NetworkDataTask dependencies
    var downloadState: ImageDownloadState = .new
    var percentComplete: Double = 0
    var thumbnail: UIImage?

    // Model properties
    var imageId: String = ""
    var link: String = ""
    var name: String = ""
    var title: String = ""
    var description: String = ""
    var datetime: Date?
    var type: String = ""
    var favorite: Bool = false
    var height: Int = 0
    var width: Int = 0
    var size: Int64 = 0
    var views: Int = 0
    var deleteHash: String = ""

    enum CodingKeys: String, CodingKey {
        case imageId = "id"
        case link
        case name
        case title
        case description
        case datetime
        case type
        case favorite
        case height
        case width
        case size
        case views
        case deleteHash = "deletehash"
    }

    required init(from decoder: Decoder) {
        guard let values = try? decoder.container(keyedBy: CodingKeys.self) else { return }

        self.imageId = (try? values.decode(String.self, forKey: .imageId)) ?? ""
        self.link = (try? values.decode(String.self, forKey: .link)) ?? ""
        self.name = (try? values.decode(String.self, forKey: .name)) ?? ""
        self.title = (try? values.decode(String.self, forKey: .title)) ?? ""
        self.description = (try? values.decode(String.self, forKey: .description)) ?? ""
        if let datetime = (try? values.decode(Int64.self, forKey: .datetime)) {
            self.datetime = Date(timeIntervalSince1970: TimeInterval(integerLiteral: datetime))
        }
        self.type = (try? values.decode(String.self, forKey: .type)) ?? ""
        self.favorite = (try? values.decode(Bool.self, forKey: .favorite)) ?? false
        self.height = (try? values.decode(Int.self, forKey: .height)) ?? 0
        self.width = (try? values.decode(Int.self, forKey: .width)) ?? 0
        self.size = (try? values.decode(Int64.self, forKey: .size)) ?? 0
        self.views = (try? values.decode(Int.self, forKey: .views)) ?? 0
        self.deleteHash = (try? values.decode(String.self, forKey: .deleteHash)) ?? ""
    }

}
