//
//  FetchClient.swift
//  image-gallery
//
//  Created by Александр Христо on 14.06.2019.
//  Copyright © 2019 Александр Христо. All rights reserved.
//

import UIKit
import Alamofire;
import CoreData;

class FetchClient {
    let apiKey = "a2f7a2f240bcaa98182b4ce467dbeb9e"
    
    enum Error: Swift.Error {
        case unknownAPIResponse
        case generic
    }
    
    func saveResultsToCoreData(photos: [Photo], searchTerm: String) {
        let managedContext = CoreDataManager.shared.persistentContainer.viewContext
        managedContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        let entity =
            NSEntityDescription.entity(forEntityName: "ListItemEntity",
                                       in: managedContext)!
        
        photos.enumerated().forEach({ (offset, photo) in
            let photoObj = NSManagedObject(entity: entity,
                                           insertInto: managedContext)
            
            photoObj.setValue(photo.farm, forKey: "farm")
            photoObj.setValue(photo.server, forKey: "server")
            photoObj.setValue(photo.secret, forKey: "secret")
            photoObj.setValue(photo.photoID, forKey: "photo_id")
            photoObj.setValue(photo.photoID, forKey: "photo_id")
            photoObj.setValue(searchTerm, forKey: "search_term")
            photoObj.setValue(offset, forKey: "offset")
        })
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func fetchResultsFromCoreData(searchTerm: String) -> [Photo]? {
        let managedContext = CoreDataManager.shared.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ListItemEntity")
        fetchRequest.predicate = NSPredicate(format: "search_term == %@", searchTerm)
        
        guard
            let photoObjs = try? managedContext.fetch(fetchRequest)
            else {
                print("Could not fetch")
                return nil
        }
        print("found")
        
        let sortedPhotoObjs = photoObjs.sorted(by: { ($1.value(forKey: "offset") as! Int) > ($0.value(forKey: "offset") as! Int) })
        
        let photos: [Photo] = sortedPhotoObjs.compactMap { photoObject in
            guard
                let photoID = photoObject.value(forKey: "photo_id") as? String,
                let farm = photoObject.value(forKey: "farm") as? Int,
                let server = photoObject.value(forKey: "server") as? String,
                let secret = photoObject.value(forKey: "secret") as? String
                else {
                    return nil
            }
            
            
            let photo = Photo(photoID: photoID, farm: farm, server: server, secret: secret)
            
            return photo
        }
        
        return photos.count > 0 ? photos : nil
    }
    
    func clearResultsFromCoreData() {
        let managedContext = CoreDataManager.shared.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ListItemEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try managedContext.execute(deleteRequest)
            try managedContext.save()
        } catch let error as NSError {
            print("Error during delete. \(error), \(error.userInfo)")
        }
    }
    
    public func getImages(for searchTerm: String, completion: @escaping (Result<FetchResults>) -> Void) {
        self.fetchImages(for: searchTerm, completion: { fetchResults in
            switch fetchResults {
            case .error(let error):
                
                if let savedImages = self.fetchResultsFromCoreData(searchTerm: searchTerm) {
                    print("Saved list found")
                    let coreDataResults = FetchResults(searchTerm: searchTerm, searchResults: savedImages, cached: true)
                    DispatchQueue.main.async {
                        completion(Result.results(coreDataResults))
                    }
                } else {
                    print("Saved list not found, fetch failed")
                    completion(Result.error(error))
                }
            case .results(let results):
                print("Got list from internet")
                completion(Result.results(results))
            }
        })
        
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
                    
                    self.saveResultsToCoreData(photos: photos, searchTerm: searchTerm)
                    
                    let fetchResults = FetchResults(searchTerm: searchTerm, searchResults: photos, cached: false)
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
