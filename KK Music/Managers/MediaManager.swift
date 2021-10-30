//
//  MediaManager.swift
//  KK Music
//
//  Created by Nolin McFarland on 10/27/21.
//

import Foundation
import AVFoundation

protocol MediaManagerDelegate {
    func mediaStatusChanged()
    func mediaTimeChanged()
}

struct MediaManager {
    
    private static var mediaPlayer: AVPlayer?
    private static var mediaUrl: String?
    
    static var songs = [Song]()
    
    static var delegate: MediaManagerDelegate?
    
    static var currentSongIndex: Int?
    static var currentSong: Song? {
        guard let currentSongIndex = currentSongIndex else { return nil }
        return songs[currentSongIndex]
    }
    
    static var isPlaying: Bool {
        return (mediaPlayer?.rate != 0 && mediaPlayer?.error == nil)
    }
    
    static var currentSongTime: Int {
        if let seconds = mediaPlayer?.currentItem?.currentTime().seconds {
            return Int(seconds)
        } else {
            return 0
        }
    }
    
    static var currentSongDuration: Int {
        if let seconds = mediaPlayer?.currentItem?.duration.seconds {
            if seconds.isNaN {
                return 0
            }
            return Int(seconds)
        } else {
            return 0
        }
    }
    
    static var currentSongProgress: Float {
        guard currentSongDuration > 0 else { return 0 }
        guard let mediaPlayer = mediaPlayer, let currentItem = mediaPlayer.currentItem else { return 0 }
        
        let timeSeconds = Double(currentItem.currentTime().seconds)
        let durationSeconds = Double(currentItem.duration.seconds)
    
        return Float(
            ((timeSeconds / durationSeconds) * 1000).rounded() / 1000
        )
    }
    
    static func play(_ newIndex: Int? = nil) {
        if let newIndex = newIndex {
             currentSongIndex = newIndex
        }
        guard let currentSongIndex = currentSongIndex, currentSongIndex < songs.count else { return }
        
        let song = songs[currentSongIndex]
        
        guard let urlString = song.music_uri else { return }
        
        // If mediaURL is not nil, matches current song url, and no newIndex is passed, resume.
        if let mediaUrl = mediaUrl {
            if mediaUrl == urlString && newIndex == nil {
                mediaPlayer?.play()
                delegate?.mediaStatusChanged()
                return
            }
        }
        
        if let url = URL(string: urlString) {
            let playerItem = AVPlayerItem(url: url)
            mediaPlayer = AVPlayer(playerItem: playerItem)
            
            mediaPlayer?.volume = 1
            mediaPlayer?.play()
            
            mediaPlayer!.addPeriodicTimeObserver(forInterval: CMTime.init(seconds: 1/1000, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: DispatchQueue.main) { [self] (time) in
                delegate?.mediaTimeChanged()
                checkIfMediaEnded()
            }
            
            mediaUrl = urlString
        }
    }
    
    static func pause() {
        mediaPlayer?.pause()
        delegate?.mediaStatusChanged()
    }
    
    static func forward() {
        guard currentSongIndex != nil else { return }
        
        currentSongIndex! += 1
        if currentSongIndex! >= songs.count {
            currentSongIndex! = 0
        }
        
        play()
        delegate?.mediaStatusChanged()
    }
    
    static func backward() {
        guard currentSongIndex != nil else { return }
        
        // If current time is >= 5 restart song, otherwise go to previous song
        if currentSongTime >= 5 {
            mediaUrl = nil
        } else {
            currentSongIndex! -= 1
            if currentSongIndex! < 0 {
                currentSongIndex = songs.count - 1
            }
        }
        
        play()
        delegate?.mediaStatusChanged()
    }
    
    static func scrub(_ progress: Float) {
        let newTime = progress * Float(currentSongDuration)
        let newCMTime = CMTimeMake(value: Int64(newTime), timescale: 1)
        mediaPlayer?.seek(to: newCMTime)
        delegate?.mediaTimeChanged()
        checkIfMediaEnded()
    }
    
    static func checkIfMediaEnded() {
        guard currentSongDuration > 0 else { return }
        // Most songs only reach 0.999 progress
        if currentSongProgress >= 0.999 {
            // Media ended, skip forward to next song
            forward()
        }
    }
}
