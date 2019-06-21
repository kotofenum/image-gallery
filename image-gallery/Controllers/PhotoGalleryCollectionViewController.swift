//
//  PhotoGalleryCollectionViewController.swift
//  image-gallery
//
//  Created by Александр Христо on 14.06.2019.
//  Copyright © 2019 Александр Христо. All rights reserved.
//

import UIKit

class PhotoGalleryCollectionViewController: UICollectionViewController {
    private let sectionInsets = UIEdgeInsets(top: 50.0,
                                             left: 20.0,
                                             bottom: 50.0,
                                             right: 20.0)
    
    private let itemsPerRow: CGFloat = 3
    private let dataSource = GalleryDataSource()

    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout! {
        didSet {
//            flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
//            Если включить авторастягивание, перестает вызываться prefetchItemsAt
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.dataSource = dataSource
        collectionView.prefetchDataSource = dataSource
        
        dataSource.searchPhotos(text: "cats", completion: { results in
            switch results {
            case .error(let error):
                self.toast(msg: error.localizedDescription)
            case .results( _):
                self.collectionView?.reloadData()
            }
        })
    }
}

extension PhotoGalleryCollectionViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let activityIndicator = UIActivityIndicatorView(style: .gray)
        textField.addSubview(activityIndicator)
        activityIndicator.frame = textField.bounds
        activityIndicator.startAnimating()
        
        let trimmedText = textField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        dataSource.searchTerm = trimmedText
        
        dataSource.searchPhotos(text: trimmedText, completion: { results in
            switch results {
            case .error(let error):
                activityIndicator.removeFromSuperview()
                self.toast(msg: error.localizedDescription)
            case .results( _):
                print("Ok")
                activityIndicator.removeFromSuperview()
                self.collectionView?.reloadData()
            }
        })

        textField.text = nil
        textField.resignFirstResponder()
        return true
    }

    public func toast(msg: String) {
        let alertDisapperTimeInSeconds = 2.0
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .actionSheet)
        self.present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + alertDisapperTimeInSeconds) {
        alert.dismiss(animated: true)
        }
    }
}

extension PhotoGalleryCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = dataSource.photo(for: indexPath)
        
        performSegue(withIdentifier: "showImage", sender: item)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showImage"{
            let destinationController = segue.destination as? ImageViewController
            destinationController?.photo = sender as? Photo
        }
    }
}

extension PhotoGalleryCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

