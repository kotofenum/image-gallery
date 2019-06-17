//
//  Photo.swift
//  image-gallery
//
//  Created by Александр Христо on 14.06.2019.
//  Copyright © 2019 Александр Христо. All rights reserved.
//

import UIKit

class Photo: NSObject, NSCoding {
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(thumbnail, forKey: "thumbnail")
        aCoder.encode(largeImage, forKey: "largeImage")
        aCoder.encode(cachedAt, forKey: "cachedAt")
        aCoder.encode(photoID, forKey: "photoID")
        aCoder.encode(farm, forKey: "farm")
        aCoder.encode(server, forKey: "server")
        aCoder.encode(secret, forKey: "secret")
        print("'encoding'")
        print(aCoder)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard
            let thumbnail = aDecoder.decodeObject(forKey: "thumbnail") as? UIImage,
            let largeImage = aDecoder.decodeObject(forKey: "largeImage") as? UIImage,
            let cachedAt = aDecoder.decodeObject(forKey: "cachedAt") as? Date,
            let photoID = aDecoder.decodeObject(forKey: "photoID") as? String,
            let farm = aDecoder.decodeObject(forKey: "farm") as? Int,
            let server = aDecoder.decodeObject(forKey: "server") as? String,
            let secret = aDecoder.decodeObject(forKey: "secret") as? String
            else {
                return nil
        }
        self.init(thumbnail: thumbnail,
                  largeImage: largeImage,
                  cachedAt: cachedAt,
                  photoID: photoID,
                  farm: farm,
                  server: server,
                  secret: secret
                  )
    }
    
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
        if let url =  URL(string: "https://farm\(farm).staticflickr.com/\(server)/\(photoID)_\(secret)_\(size).jpg") {
            return url
        }
        return nil
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
    
    static func == (lhs: Photo, rhs: Photo) -> Bool {
        return lhs.photoID == rhs.photoID
    }
}
