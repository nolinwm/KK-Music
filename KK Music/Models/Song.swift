//
//  Song.swift
//  KK Music
//
//  Created by Nolin McFarland on 2/6/21.
//

import Foundation

struct Song: Decodable {
    
    var id: Int
    var name: [String: String]?
    var music_uri: String?
    var image_uri: String?
    
    func getName() -> String {
        guard name != nil else { return "" }
        
        if let usEnName = name!["name-USen"] {
            return usEnName
        } else {
            return ""
        }
        
    }
}
