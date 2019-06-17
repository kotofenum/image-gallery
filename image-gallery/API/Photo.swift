//
//  Photo.swift
//  image-gallery
//
//  Created by Александр Христо on 14.06.2019.
//  Copyright © 2019 Александр Христо. All rights reserved.
//

import UIKit

class Photo: Equatable {
    var thumbnail: UIImage?
    var largeImage: UIImage?
    let photoID: String
    let farm: Int
    let server: String
    let secret: String
    let imageCache = NSCache<NSString, UIImage>()
    
    init (photoID: String, farm: Int, server: String, secret: String) {
        self.photoID = photoID
        self.farm = farm
        self.server = server
        self.secret = secret
    }
    
    func getImageURL(_ size: String = "m") -> URL? {
        if let url =  URL(string: "https://farm\(farm).staticflickr.com/\(server)/\(photoID)_\(secret)_\(size).jpg") {
            return url
        }
        return nil
    }
    
    func loadImage(_ completion: @escaping (Result<Photo>) -> Void) {
        let loadURL = getImageURL()
        
        if let cachedImage = imageCache.object(forKey: loadURL!.absoluteString as NSString) {
            self.largeImage = cachedImage
            print("restore from cache")
            completion(Result.results(self))
        } else {
            print("load from internet")
            let loadRequest = URLRequest(url: loadURL!)
            
            URLSession.shared.dataTask(with: loadRequest) { (data, response, error) in
                
                guard let data = data else {
                    DispatchQueue.main.async {
                        completion(Result.error(error!))
                    }
                    return
                }
                
                let returnedImage = UIImage(data: data)
                self.largeImage = returnedImage
                DispatchQueue.main.async {
                    completion(Result.results(self))
                }
            }.resume()
        }
    }
    
    func sizeToFillWidth(of size: CGSize) -> CGSize {
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
    
    static func == (lhs: Photo, rhs: Photo) -> Bool {
        return lhs.photoID == rhs.photoID
    }
}
