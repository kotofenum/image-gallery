//
//  GalleryDataSource.swift
//  image-gallery
//
//  Created by Александр Христо on 21.06.2019.
//  Copyright © 2019 Александр Христо. All rights reserved.
//

import UIKit

enum PhotoError: Error {
    case badConnectionWithCache
}

extension PhotoError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .badConnectionWithCache:
            return NSLocalizedString("Bad connection, using cached data.", comment: "")
        }
    }
}

class GalleryDataSource: NSObject, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching {
    private let reuseIdentifier = "ImageCell"
    
    private var searches: [FetchResults] = []
    private let client = FetchClient()
    
    public var searchTerm: String = "cats"
    
    private var page: Int = 1
    private var total: Int = 0
    
    private var fetchingData: Bool = false
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return searches.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searches[section].searchResults.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! GalleryCollectionViewCell
        let image = photo(for: indexPath)
        
        cell.title.text = image.title
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
                        cell.sizes.text = "W: \(cell.bounds.width), H: \(cell.bounds.height)"
                    }
                })
                
                return cell
        }
        
        print("Image at \(indexPath) already set")
        
        cell.imageView.image = image.thumbnail
        cell.sizes.text = "W: \(cell.bounds.width), H: \(cell.bounds.height)"
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
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
            fatalError("Invalid element type")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        if indexPaths.contains(where: isFetchingNeeded) {
            page += 1
            fetchAndPopulateImages(completion: { results in
                switch results {
                case .error(let error):
                    print(error.localizedDescription)
                case .results( _):
                    collectionView.reloadData()
                }
            })
        }
        for indexPath in indexPaths {
            let image = photo(for: indexPath)
            
            guard
                image.thumbnail != nil
                else {
                    ImageManager.shared.loadImage(forPhoto: image, { result in
                        
                        switch result {
                        case .error(let error):
                            print("Error loading image: \(error)")
                        case .results(let image):
                            print(image.thumbnail)
                        }
                    })
                return
            }
            
        }
    }
    
    func isFetchingNeeded(for indexPath: IndexPath) -> Bool {
        return indexPath.item >= searches[0].searchResults.count - 10
    }
    
    func searchPhotos(text: String, completion: @escaping (Result<Int>) -> Void) {
        setSearchTerm(searchTerm: text)
        fetchAndPopulateImages(completion: completion)
    }
        
    func fetchAndPopulateImages(completion: @escaping (Result<Int>) -> Void) {
        if (!fetchingData) {
            fetchingData = true
            client.getImages(for: searchTerm, page: page) { searchResults in
                
                switch searchResults {
                case .error(let error):
                    print("Error Searching: \(error)")
                    completion(Result.error(error))
                case .results(let results):
                    print("Found \(results.searchResults.count) matching \(results.searchTerm)")
                    
                    if (results.cached) {
                        completion(Result.error(PhotoError.badConnectionWithCache));
                    }
                    
                    if (self.searches.count > 0) {
                        self.searches[0].searchResults += results.searchResults
                    } else {
                        self.searches = [results]
                    }
                    
                    self.fetchingData = false
                    
                    completion(Result.results(self.searches[0].searchResults.count));
                }
            }
        } else {
            print("Data are fetching already")
        }
    }
    
    func photo(for indexPath: IndexPath) -> Photo {
        return searches[indexPath.section].searchResults[indexPath.row]
    }
    
    public func setSearchTerm(searchTerm: String) {
        self.searches = []
        self.searchTerm = searchTerm
        self.page = 1
        self.fetchingData = false
    }
}
