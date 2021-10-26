//
//  LibraryManager.swift
//  KK Music
//
//  Created by Nolin McFarland on 10/25/21.
//

import Foundation

struct LibraryManager {
    
    static func isAddedToLibrary(id: Int) -> Bool {
        let defaults = UserDefaults.standard
        let library = defaults.value(forKey: "library") as? [Int] ?? [Int]()
        return library.contains(id)
    }
    
    static func removeFromLibrary(id: Int) {
        let defaults = UserDefaults.standard
        var library = defaults.value(forKey: "library") as? [Int] ?? [Int]()
        
        if let index = library.firstIndex(of: id) {
            library.remove(at: index)
        }
        
        defaults.set(library, forKey: "library")
    }
    
    static func addToLibrary(id: Int) {
        let defaults = UserDefaults.standard
        var library = defaults.value(forKey: "library") as? [Int] ?? [Int]()
        
        if library.firstIndex(of: id) == nil {
            library.append(id)
        }
        
        defaults.set(library, forKey: "library")
    }
}
