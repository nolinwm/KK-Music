//
//  SongModel.swift
//  KK Music
//
//  Created by Nolin McFarland on 2/6/21.
//

import Foundation

protocol SongModelProtocol {
    func songsRetrieved(_ songs: [Song])
}

struct SongModel {
    
    let apiURL = "https://acnhapi.com/v1/songs"
    
    var delegate: SongModelProtocol?
    
    func fetchSongs() {
        
        // Create URL Object
        let url = URL(string: apiURL)
        guard url != nil else { return }
        
        // Create URL Session
        let session = URLSession.shared
        
        // Create Data Task
        let dataTask = session.dataTask(with: url!) { (data, response, error) in
            
            if error == nil && data != nil {
                let decoder = JSONDecoder()
                do {
                    let songsDictionary = try decoder.decode([String: Song].self, from: data!)
                    DispatchQueue.main.async {
                        
                        let songs = self.convertDictionaryToArray(songsDictionary)
                        let sortedSongs = sortArrayAlphabetically(songs)
                        self.delegate?.songsRetrieved(sortedSongs)
                        
                    }
                } catch {
                    print("Error fetching and decoding songs.")
                }
            }
        }
        
        // Resume Data Task
        dataTask.resume()
    }
    
    func sortArrayAlphabetically(_ songs: [Song]) -> [Song] {
        var sorted = songs
        for _ in 0 ..< sorted.count{
            for j in 0 ..< sorted.count-1 {
                if sorted[j].getName() > sorted[j+1].getName() {
                    sorted.swapAt(j, j+1)
                }
            }
        }
        return sorted
    }
    
    func convertDictionaryToArray(_ dictionary: [String: Song]) -> [Song] {
        var array = [Song]()
        
        for (_, song) in dictionary {
            array.append(song)
        }
        
        return array
    }
}
