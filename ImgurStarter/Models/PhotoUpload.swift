//
//  PhotoUpload.swift
//  ImgurStarter
//
//  Created by Stuart Levine on 5/26/18.
//  Copyright © 2018 Wildcat Productions. All rights reserved.
//

import Foundation
import UIKit

// The photo model for uploading a photo to imgur

struct PhotoUpload: Codable {

    var photo: UIImage?
    var image: String = ""
    var title: String = ""
    var name: String = ""
    var description: String = ""
    var type: String = "base64"

    enum CodingKeys: String, CodingKey {
        case image
        case title
        case name
        case description
        case type
    }

    init(photo: UIImage, title: String? = nil, name: String? = nil, description: String? = nil) {
        self.title = title ?? ""
        self.name = name ?? ""
        self.photo = photo

        guard let imageData = photo.jpegData(compressionQuality: jpegQuality) else { return }

        self.image = imageData.base64EncodedString()
        if let description = description {
            self.description = description
        }
    }

    init(from decoder: Decoder) throws {
        guard let values = try? decoder.container(keyedBy: CodingKeys.self) else { return }

        self.image = (try? values.decode(String.self, forKey: .image)) ?? ""
        self.title = (try? values.decode(String.self, forKey: .title)) ?? ""
        self.name = (try? values.decode(String.self, forKey: .name)) ?? ""
        self.description = (try? values.decode(String.self, forKey: .description)) ?? ""
        self.type = (try? values.decode(String.self, forKey: .type)) ?? "base64"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.image, forKey: .image)
        try container.encode(self.title, forKey: .title)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.description, forKey: .description)
        try container.encode(self.type, forKey: .type)
    }
}
