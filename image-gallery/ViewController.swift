//
//  ViewController.swift
//  image-gallery
//
//  Created by Александр Христо on 13.06.2019.
//  Copyright © 2019 Александр Христо. All rights reserved.
//

import UIKit
import Alamofire;

struct Image: Codable {
    var id: String
    var author: String
    var download_url: String
    var height: Int
    var width: Int
    var url: String
    
    init(_ dictionary: [String: Any]) {
        self.id = dictionary["id"] as? String ?? ""
        self.author = dictionary["author"] as? String ?? ""
        self.download_url = dictionary["download_url"] as? String ?? ""
        self.height = dictionary["height"] as? Int ?? 0
        self.width = dictionary["width"] as? Int ?? 0
        self.url = dictionary["url"] as? String ?? ""
    }
    
}

class ViewController: UIViewController {
    
    @IBOutlet weak var MyImage: UIImageView!
    var images: [Image] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.fetchImages(completion: { images in
//            self.images = images!
//            print(images)
//            self.downloadImage(from: NSURL(string: self.images[0].download_url)! as URL)
//        })
//        
//        print(self.images)
    }
    
    func downloadImage(from url: URL) {
        print("Download Started")
        getData(from: url) { data, response, error in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            print("Download Finished")
            DispatchQueue.main.async() {
                self.MyImage.image = UIImage(data: data)
            }
        }
    }
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    public func fetchImages(completion: @escaping ([Image]?) -> ()) {
        Alamofire.request("https://picsum.photos/v2/list?page=2&limit=10").responseJSON { response in
            
            if response.result.isSuccess {
                
                guard let data = response.data else { return }
                
                do {
                    let images = try! JSONDecoder().decode([Image].self, from: data)
                    return completion(images)
                }
                catch {}
            }
        }
    }


}

