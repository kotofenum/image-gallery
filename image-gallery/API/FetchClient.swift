//
//  FetchClient.swift
//  image-gallery
//
//  Created by Александр Христо on 14.06.2019.
//  Copyright © 2019 Александр Христо. All rights reserved.
//

import UIKit
import Alamofire;

class FetchClient {
    let apiKey = "a2f7a2f240bcaa98182b4ce467dbeb9e"
    
    enum Error: Swift.Error {
        case unknownAPIResponse
        case generic
    }
    
    public func fetchImages(for searchTerm: String, completion: @escaping (Result<FetchResults>) -> Void) {
        Alamofire.request("https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&text=\(searchTerm)&format=json&nojsoncallback=1").responseJSON { response in
            
            if response.result.isSuccess {
                guard let data = response.data else { return }
                
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

                        return photo
                    }
                    
                    let fetchResults = FetchResults(searchTerm: searchTerm, searchResults: photos)
                    DispatchQueue.main.async {
                        completion(Result.results(fetchResults))
                    }
                } catch {
                    completion(Result.error(error))
                    return
                }
            } else {
                DispatchQueue.main.async {
                    completion(Result.error(response.error!))
                    return
                }
            }
        }
    }
}
