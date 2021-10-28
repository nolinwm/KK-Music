//
//  CacheManager.swift
//  KK Music
//
//  Created by Nolin McFarland on 10/24/21.
//

import Foundation
import UIKit

struct CacheManager {
    
    static var imageCache = [String: Data]()
    
    static func saveImage(_ urlString: String, _ data: Data) {
        imageCache[urlString] = data
    }
    
    static func fetchImage(_ urlString: String) -> Data? {
        return imageCache[urlString]
    }
}
