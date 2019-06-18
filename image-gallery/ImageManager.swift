//
//  ImageManager.swift
//  image-gallery
//
//  Created by Александр Христо on 17.06.2019.
//  Copyright © 2019 Александр Христо. All rights reserved.
//

import UIKit
import Alamofire
import CoreData

class ImageManager {
    static let shared = ImageManager()

    private let imageCache = NSCache<NSString, NSString>()
    
    private init() {}
    
    func saveImageMeta(url: String, filename: String, cachedAt: Date) {
        
        let managedContext = CoreDataManager.shared.persistentContainer.viewContext
        managedContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        let entity =
            NSEntityDescription.entity(forEntityName: "PhotoEntity",
                                       in: managedContext)!
        
        let photo = NSManagedObject(entity: entity,
                                     insertInto: managedContext)
        
        photo.setValue(url, forKey: "image_web_url")
        photo.setValue(filename, forKey: "image_local_name")
        photo.setValue(cachedAt, forKey: "cached_at")
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func fetchImageMeta(url: String) -> NSManagedObject? {
        let managedContext = CoreDataManager.shared.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "PhotoEntity")
        fetchRequest.predicate = NSPredicate(format: "image_web_url == %@", url)
        
        guard
            let imageMeta = try? managedContext.fetch(fetchRequest).first
            else {
                print("Could not fetch")
                return nil
        }
        
        return imageMeta
    }
    
    func loadImage(forPhoto photo: Photo, size: String = "m", _ completion: @escaping (Result<Photo>) -> Void) {
        let url = photo.getImageURL(size)
        
        if let savedImageMeta = self.fetchImageMeta(url: url!.absoluteString) {
            print("Restore from cache")
            let cacheDate = savedImageMeta.value(forKey: "cached_at") as! Date
            let imageFileName = savedImageMeta.value(forKey: "image_local_name") as! String
            
            let savedImage = self.getImageFromDocsDir(filename: imageFileName)
            
            photo.thumbnail = savedImage
            photo.cachedAt = cacheDate
            completion(Result.results(photo))
        } else {
            print("Load from internet")
            
            Alamofire.request(url!, method: .get).response { response in
                guard
                    let data = response.data
                    else {
                    DispatchQueue.main.async {
                        completion(Result.error(response.error!))
                    }
                    return
                }
                guard
                    let returnedImage = UIImage(data: data)
                    else {
                        DispatchQueue.main.async {
                            completion(Result.error(response.error!))
                        }
                        return
                }
                
                let cacheDate = Date()
                photo.cachedAt = cacheDate
                
                let imageName = photo.getImageName()
                
                self.saveImageInDocsDir(image: returnedImage, filename: imageName)
                self.imageCache.setObject(imageName as NSString, forKey: url!.absoluteString as NSString)
                
                self.saveImageMeta(url: url!.absoluteString, filename: imageName, cachedAt: cacheDate)
                
                let savedImage = self.getImageFromDocsDir(filename: imageName)
                
                photo.thumbnail = savedImage
                DispatchQueue.main.async {
                    completion(Result.results(photo))
                }
            }
        }
    }
    
    func saveImageInDocsDir(image: UIImage, filename: String) {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        let dataPath = URL(fileURLWithPath: documentsDirectory).appendingPathComponent("saved_images").path
        
        if !FileManager.default.fileExists(atPath: dataPath) {
            do {
                try FileManager.default.createDirectory(atPath: dataPath, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                print(error)
            }
        }
        
        let fileURL = URL(fileURLWithPath:dataPath).appendingPathComponent(filename)
        
        let data = image.jpegData(compressionQuality: 1.0)
        do {
            try data?.write(to: fileURL, options: .atomic)
        } catch {
            print("error:", error)
        }
    }

    func getImageFromDocsDir(filename: String) -> UIImage? {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] // Get documents folder
        let dataPath = URL(fileURLWithPath: documentsDirectory).appendingPathComponent("saved_images").path
        
        guard FileManager.default.fileExists(atPath: dataPath)
            else {
            return nil
        }

        let fileURL = URL(fileURLWithPath:dataPath).appendingPathComponent(filename)
        
        let image = UIImage(contentsOfFile: fileURL.path)
        return image
    }
    
}
