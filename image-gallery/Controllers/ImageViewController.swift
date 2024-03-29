//
//  ImageViewController.swift
//  image-gallery
//
//  Created by Александр Христо on 14.06.2019.
//  Copyright © 2019 Александр Христо. All rights reserved.
//

import UIKit
import Alamofire

class ImageViewController: UIViewController {
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var thumbDateLabel: UILabel!
    @IBOutlet weak var largeDateLabel: UILabel!
    
    
    var photo: Photo?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)

        self.thumbDateLabel.text = "Thumbnail cached at: \(photo!.getCacheDateAsString())"
        self.setImage(photo: photo!)
    }
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) -> Void {
        if gesture.direction == UISwipeGestureRecognizer.Direction.down {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    public func toast(msg: String) {
        let alertDisapperTimeInSeconds = 2.0
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .actionSheet)
        self.present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + alertDisapperTimeInSeconds) {
            alert.dismiss(animated: true)
        }
    }
    
    func setImage(photo: Photo) {
        ImageManager.shared.loadImage(forPhoto: photo, size: "c", { result in

            switch result {
            case .error(let error):
                print("Error loading image: \(error)")
                self.toast(msg: error.localizedDescription)
            case .results(let image):
                self.largeDateLabel.text = "Original cached at: \(image.getCacheDateAsString())"
                self.image.image = image.thumbnail
            }
        })
    }
}
