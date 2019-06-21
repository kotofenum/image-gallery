//
//  ImageLoadOperation.swift
//  image-gallery
//
//  Created by Александр Христо on 21.06.2019.
//  Copyright © 2019 Александр Христо. All rights reserved.
//

import UIKit

class ImageLoadOperation: Operation {
    var image: UIImage?
    var loadingCompleteHandler: ((Photo?) -> ())?
    private var _photo: Photo
    
    init(_ photo: Photo) {
        _photo = photo
    }
    
    override func main() {
        if isCancelled { return }
        
        ImageManager.shared.loadImage(forPhoto: _photo, { result in
            
            switch result {
            case .error(let error):
                print("Error loading image: \(error)")
            case .results(let photo):
                if let loadingCompleteHandler = self.loadingCompleteHandler {
                    DispatchQueue.main.async {
                        loadingCompleteHandler(photo)
                    }
                }
            }
        })
    }
}
