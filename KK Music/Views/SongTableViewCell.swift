//
//  SongTableViewCell.swift
//  KK Music
//
//  Created by Nolin McFarland on 10/25/21.
//

import UIKit

class SongTableViewCell: UITableViewCell {

    @IBOutlet weak var songImageView: UIImageView!
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var addedImageView: UIImageView!
    
    var song: Song?
    
    private func clear() {
        isSelected = false
        songNameLabel.text = nil
        songImageView.image = UIImage(named: "ImageLoading")
        addedImageView.isHidden = true
    }
    
    func display(song: Song) {
        clear()
        
        self.song = song
        songNameLabel.text = song.getName()
        
        addedImageView.isHidden = LibraryManager.isAddedToLibrary(id: song.id) ? false : true
        
        songImageView.layer.cornerRadius = 4
        loadImage()
    }
    
    func loadImage() {
        guard let song = song else { return }
        if song.image_uri != nil {
            let urlString = song.image_uri!
            
            if let data = CacheManager.fetchImage(urlString) {
                DispatchQueue.main.async {
                    self.songImageView.image = UIImage(data: data)
                }
                return
            }
            
            if let url = URL(string: urlString) {
                let session = URLSession.shared
                let dataTask = session.dataTask(with: url) { (data, response, error) in
                    if error == nil && data != nil {
                        if self.song!.image_uri! == urlString {
                            CacheManager.saveImage(urlString, data!)
                            DispatchQueue.main.async {
                                self.songImageView.image = UIImage(data: data!)
                            }
                            
                        }
                    }
                }
                dataTask.resume()
            }
        }
    }
    
}
