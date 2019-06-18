//
//  Photo.swift
//  image-gallery
//
//  Created by Александр Христо on 14.06.2019.
//  Copyright © 2019 Александр Христо. All rights reserved.
//

import UIKit

class Photo {
    var thumbnail: UIImage?
    var largeImage: UIImage?
    var cachedAt: Date?
    let photoID: String
    let farm: Int
    let server: String
    let secret: String
    
    init (photoID: String, farm: Int, server: String, secret: String) {
        self.photoID = photoID
        self.farm = farm
        self.server = server
        self.secret = secret
    }
    
    init (thumbnail: UIImage?, largeImage: UIImage?, cachedAt: Date?, photoID: String, farm: Int, server: String, secret: String) {
        self.thumbnail = thumbnail
        self.largeImage = largeImage
        self.cachedAt = cachedAt
        self.photoID = photoID
        self.farm = farm
        self.server = server
        self.secret = secret
    }
    
    public func getImageURL(_ size: String = "m") -> URL? {
        if let url = URL(string: "https://farm\(farm).staticflickr.com/\(server)/\(photoID)_\(secret)_\(size).jpg") {
            return url
        }
        return nil
    }
    
    public func getImageName(_ size: String = "m") -> String {
        let filename = "\(photoID)_\(secret)_\(size).jpg"
        return filename
    }
    
    public func getCacheDateAsString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if (cachedAt != nil) {
            let dateString = formatter.string(from: cachedAt!)
            return dateString
        } else {
            return "Not cached yet."
        }
    }
}
