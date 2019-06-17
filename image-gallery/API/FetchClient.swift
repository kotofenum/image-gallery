//
//  FetchClient.swift
//  image-gallery
//
//  Created by Александр Христо on 14.06.2019.
//  Copyright © 2019 Александр Христо. All rights reserved.
//

import UIKit

class FetchClient {
    let apiKey = "a2f7a2f240bcaa98182b4ce467dbeb9e"
    let imageCache = NSCache<NSString, UIImage>()
    
    enum Error: Swift.Error {
        case unknownAPIResponse
        case generic
    }
    
    func fetchImages(for searchTerm: String, completion: @escaping (Result<FetchResults>) -> Void) {
        guard let fetchURL = URL(string: "https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&text=\(searchTerm)&format=json&nojsoncallback=1") else {
            completion(Result.error(Error.unknownAPIResponse))
            return
        }
    
        let fetchRequest = URLRequest(url: fetchURL)
        
        URLSession.shared.dataTask(with: fetchRequest) { (data, response, error) in
            if let error = error {
                DispatchQueue.main.async {
                    completion(Result.error(error))
                }
                return
            }
            
            guard
                let _ = response as? HTTPURLResponse,
                let data = data
                else {
                    DispatchQueue.main.async {
                        completion(Result.error(Error.unknownAPIResponse))
                    }
                    return
            }
            
            do {
                guard
                    let resultsDictionary = try JSONSerialization.jsonObject(with: data) as? [String: AnyObject],
                    let stat = resultsDictionary["stat"] as? String
                    else {
                        DispatchQueue.main.async {
                            completion(Result.error(Error.unknownAPIResponse))
                        }
                        return
                }
                
                switch (stat) {
                case "ok":
                    print("Results processed OK")
                case "fail":
                    DispatchQueue.main.async {
                        completion(Result.error(Error.generic))
                    }
                    return
                default:
                    DispatchQueue.main.async {
                        completion(Result.error(Error.unknownAPIResponse))
                    }
                    return
                }
                
                guard
                    let photosContainer = resultsDictionary["photos"] as? [String: AnyObject],
                    let photosReceived = photosContainer["photo"] as? [[String: AnyObject]]
                    else {
                        DispatchQueue.main.async {
                            completion(Result.error(Error.unknownAPIResponse))
                        }
                        return
                }
                
                let photos: [Photo] = photosReceived.compactMap { photoObject in
                    guard
                        let photoID = photoObject["id"] as? String,
                        let farm = photoObject["farm"] as? Int,
                        let server = photoObject["server"] as? String,
                        let secret = photoObject["secret"] as? String
                        else {
                            return nil
                    }
                    
                    
                    let photo = Photo(photoID: photoID, farm: farm, server: server, secret: secret)
                    
                    guard
                        let url = photo.getImageURL()
                        else {
                            return nil
                    }
                    
                    
                    if let cachedImage = self.imageCache.object(forKey: url.absoluteString as NSString) {
                        photo.thumbnail = cachedImage
                        print("restore from cache")
                        return photo
                    } else {
                        print("load from internet")
                        guard
                            let imageData = try? Data(contentsOf: url as URL)
                            else {
                                return nil
                        }
                        
                        if let image = UIImage(data: imageData) {
                            self.imageCache.setObject(image, forKey: url.absoluteString as NSString)
                            photo.thumbnail = image
                            return photo
                        } else {
                            return nil
                        }
                    }
                }
                    
                let fetchResults = FetchResults(searchTerm: searchTerm, searchResults: photos)
                DispatchQueue.main.async {
                    completion(Result.results(fetchResults))
                }
            } catch {
                completion(Result.error(error))
                return
            }
        }.resume()
    }
}
