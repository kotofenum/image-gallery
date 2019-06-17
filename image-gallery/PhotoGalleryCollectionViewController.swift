//
//  PhotoGalleryCollectionViewController.swift
//  image-gallery
//
//  Created by Александр Христо on 14.06.2019.
//  Copyright © 2019 Александр Христо. All rights reserved.
//

import UIKit

class PhotoGalleryCollectionViewController: UICollectionViewController {
    private let reuseIdentifier = "ImageCell"
    private let sectionInsets = UIEdgeInsets(top: 50.0,
                                             left: 20.0,
                                             bottom: 50.0,
                                             right: 20.0)
    
    private var searches: [FetchResults] = []
    private let client = FetchClient()
    private let itemsPerRow: CGFloat = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchAndPopulateImages(text: "cats", completion: {})
    }
}

private extension PhotoGalleryCollectionViewController {
    func photo(for indexPath: IndexPath) -> Photo {
        return searches[indexPath.section].searchResults[indexPath.row]
    }
}

extension PhotoGalleryCollectionViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let activityIndicator = UIActivityIndicatorView(style: .gray)
        textField.addSubview(activityIndicator)
        activityIndicator.frame = textField.bounds
        activityIndicator.startAnimating()
        
        fetchAndPopulateImages(text: textField.text!, completion: {
            activityIndicator.removeFromSuperview()
        })
        

        textField.text = nil
        textField.resignFirstResponder()
        return true
    }
    
    func fetchAndPopulateImages(text: String, completion: @escaping () -> Void) {
        client.fetchImages(for: text) { searchResults in
            completion();
            
            switch searchResults {
            case .error(let error):
                print("Error Searching: \(error)")
            case .results(let results):
                print("Found \(results.searchResults.count) matching \(results.searchTerm)")
                self.searches.insert(results, at: 0)
                self.collectionView?.reloadData()
            }
        }
        
    }
}

extension PhotoGalleryCollectionViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return searches.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searches[section].searchResults.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! GalleryCollectionViewCell
        let image = photo(for: indexPath)
        
        cell.backgroundColor = .gray
        
        cell.imageView.image = #imageLiteral(resourceName: "placeholder.png")
        
        guard
            image.thumbnail != nil
            else {
                ImageManager.shared.loadImage(forPhoto: image, { result in
                    
                    switch result {
                    case .error(let error):
                        print("Error loading image: \(error)")
                    case .results(let image):
                        cell.imageView.image = image.thumbnail
                    }
                })
                
                return cell
        }
        
        cell.imageView.image = image.thumbnail
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = searches[indexPath.section]
        
        let item = section.searchResults[indexPath.item]
        
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
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
    
}

extension PhotoGalleryCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            guard
                let headerView = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: "\(GalleryCollectionReusableView.self)",
                    for: indexPath) as? GalleryCollectionReusableView
                else {
                    fatalError("Invalid view type")
            }
            
            let searchTerm = searches[indexPath.section].searchTerm
            headerView.label.text = searchTerm
            return headerView
        default:
            assert(false, "Invalid element type")
        }
    }
}
