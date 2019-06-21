//
//  FetchResults.swift
//  image-gallery
//
//  Created by Александр Христо on 14.06.2019.
//  Copyright © 2019 Александр Христо. All rights reserved.
//

import Foundation

struct FetchResults {
    let searchTerm : String
    var searchResults : [Photo]
    let cached : Bool
}
