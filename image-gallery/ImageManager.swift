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

    private let imageCache = NSCache<NSString, NSString>()
    
    override private init() {
    }
    
    func loadImage(forPhoto photo: Photo, size: String = "m", _ completion: @escaping (Result<Photo>) -> Void) {
        let url = photo.getImageURL(size)
        
        if let cachedImageName = self.imageCache.object(forKey: url!.absoluteString as NSString) {
            print("Restore from cache")
            
            let savedImage = self.getImageFromDocsDir(filename: cachedImageName as String)
            
            photo.thumbnail = savedImage
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
                
                let savedImage = self.getImageFromDocsDir(filename: imageName)
                print(savedImage)
                
                photo.thumbnail = savedImage
                DispatchQueue.main.async {
                    completion(Result.results(photo))
                }
            }
        }
    }
    
    func saveImageInDocsDir(image: UIImage, filename: String) {
        // get the documents directory url
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] // Get documents folder
        let dataPath = URL(fileURLWithPath: documentsDirectory).appendingPathComponent("saved_images").path //Set folder name
        //Check is folder available or not, if not create
        if !FileManager.default.fileExists(atPath: dataPath) {
            do {
                try FileManager.default.createDirectory(atPath: dataPath, withIntermediateDirectories: true, attributes: nil) //Create folder if not
            } catch let error {
                print(error)
            }
        }
        
        
        // create the destination file url to save your image
        let fileURL = URL(fileURLWithPath:dataPath).appendingPathComponent(filename)//Your image name
        print(fileURL)
        // get your UIImage jpeg data representation
        let data = image.jpegData(compressionQuality: 1.0)
        do {
            // writes the image data to disk
            try data?.write(to: fileURL, options: .atomic)
        } catch {
            print("error:", error)
        }
    }

    func getImageFromDocsDir(filename: String) -> UIImage? {
        // get the documents directory url
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] // Get documents folder
        let dataPath = URL(fileURLWithPath: documentsDirectory).appendingPathComponent("saved_images").path //Set folder name
        print(dataPath)
        //Check is folder available or not, if not create
        guard FileManager.default.fileExists(atPath: dataPath)
            else {
            return nil
        }
        
        // create the destination file url to save your image
        let fileURL = URL(fileURLWithPath:dataPath).appendingPathComponent(filename)//Your image name
        print(fileURL)
        // get your UIImage jpeg data representation
        let image = UIImage(contentsOfFile: fileURL.path)
        return image
    }
    
}
