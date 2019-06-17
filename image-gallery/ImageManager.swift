//
//  ImageManager.swift
//  image-gallery
//
//  Created by Александр Христо on 17.06.2019.
//  Copyright © 2019 Александр Христо. All rights reserved.
//

import UIKit
import Alamofire

class ImageManager: NSObject {
    static let shared = ImageManager()

    private let imageCache = NSCache<NSString, UIImage>()
    
    override private init() {
    }
    
    func loadImage(forPhoto photo: Photo, size: String = "m", _ completion: @escaping (Result<Photo>) -> Void) {
        let url = photo.getImageURL(size)
        
        if let cachedImage = self.imageCache.object(forKey: url!.absoluteString as NSString) {
            print("Restore from cache")
            
            photo.thumbnail = cachedImage
            completion(Result.results(photo))
        } else {
            print("Load from internet")
            
            Alamofire.request(url!, method: .get).response { response in
                guard let data = response.data else {
                    DispatchQueue.main.async {
                        completion(Result.error(response.error!))
                    }
                    return
                }
                let returnedImage = UIImage(data: data)
                self.imageCache.setObject(returnedImage!, forKey: url!.absoluteString as NSString)
                let cacheDate = Date()
                photo.cachedAt = cacheDate
                photo.thumbnail = returnedImage
                DispatchQueue.main.async {
                    completion(Result.results(photo))
                }
            }
        }
    }
    
}
