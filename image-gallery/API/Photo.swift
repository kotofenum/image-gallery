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
    let title: String
    
    init (photoID: String, farm: Int, server: String, secret: String, title: String) {
        self.photoID = photoID
        self.farm = farm
        self.server = server
        self.secret = secret
        self.title = title
    }
    
    init (thumbnail: UIImage?, largeImage: UIImage?, cachedAt: Date?, photoID: String, farm: Int, server: String, secret: String, title: String) {
        self.thumbnail = thumbnail
        self.largeImage = largeImage
        self.cachedAt = cachedAt
        self.photoID = photoID
        self.farm = farm
        self.server = server
        self.secret = secret
        self.title = title
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
    
    public func sizeToFillWidth(of size:CGSize) -> CGSize {
        guard let thumbnail = thumbnail else {
            return size
        }
        
        let imageSize = thumbnail.size
        var returnSize = size
        
        let aspectRatio = imageSize.width / imageSize.height
        
        returnSize.height = returnSize.width / aspectRatio
        
        if returnSize.height > size.height {
            returnSize.height = size.height
            returnSize.width = size.height * aspectRatio
        }
        
        return returnSize
    }
    
//    public func getCellSize() -> CGSize {
//        let thumbnail = thumbnail 
//        
//        let aspectRatio = imageSize.
//    }
}
