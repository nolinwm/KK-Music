//
//  MediaManager.swift
//  KK Music
//
//  Created by Nolin McFarland on 10/24/21.
//

import Foundation
import AVFoundation

protocol MediaManagerProtocol {
    func mediaCurrentTimeChanged(_ currentTime: Float64, _ duration: Float64)
}

struct MediaManager {
    
    static var songs = [Song]()
    static var librarySongs: [Song] {
        var librarySongs = [Song]()
        for song in songs {
            if LibraryManager.isAddedToLibrary(id: song.id) {
                librarySongs.append(song)
            }
        }
        return librarySongs
    }
    static var currentIndex: Int?
    
    static var mediaPlayer: AVPlayer?
    static var mediaUrl: String?
    static var isPlaying = false
    
    static var delegate: MediaManagerProtocol?
    
    static func play() {
        guard let currentIndex = currentIndex else { return }
        let song = songs[currentIndex]
        
        guard let urlString = song.music_uri else { return }
        
        if mediaUrl != nil {
            if mediaUrl == urlString {
                mediaPlayer!.play()
                isPlaying = true
                return
            }
        }
        
        if let url = URL(string: urlString) {
            
            let playerItem = AVPlayerItem(url: url)
            print(playerItem.currentTime())
            mediaPlayer = AVPlayer(playerItem: playerItem)
            mediaPlayer!.volume = 1
            mediaPlayer!.play()

            mediaPlayer!.addPeriodicTimeObserver(forInterval: CMTime.init(seconds: 1/1000, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: DispatchQueue.main) { [self] (time) in
                let currentTime = CMTimeGetSeconds(mediaPlayer!.currentItem!.currentTime())
                let duration = CMTimeGetSeconds(mediaPlayer!.currentItem!.duration)
                delegate?.mediaCurrentTimeChanged(currentTime, duration)
            }
            
            mediaUrl = urlString
            isPlaying = true
        }
    }
    
    static func pause() {
        mediaPlayer?.pause()
        isPlaying = false
    }
    
    static func forward() {
        guard currentIndex != nil else { return }
        currentIndex! += 1
        if currentIndex! >= songs.count {
            currentIndex = 0
        }
        play()
    }
    
    static func backward() {
        guard currentIndex != nil else { return }
        currentIndex! -= 1
        if currentIndex! < 0 {
            currentIndex = songs.count - 1
        }
        play()
    }
}
