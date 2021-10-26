//
//  MediaViewController.swift
//  KK Music
//
//  Created by Nolin McFarland on 10/24/21.
//

import UIKit

class MediaViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var dragBar: UIView!
    @IBOutlet weak var songImageShadowView: UIView!
    @IBOutlet weak var songImageView: UIImageView!
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var addedButton: UIButton!
    @IBOutlet weak var scrubBar: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var backwardButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    var notification: (String, String) = ("","")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        containerView.layer.cornerRadius = 30
        
        dragBar.layer.cornerRadius = 3
        
        songImageView.layer.cornerRadius = 12
        songImageShadowView.layer.cornerRadius = 12
        songImageShadowView.layer.shadowColor = UIColor.black.cgColor
        songImageShadowView.layer.shadowRadius = 15
        songImageShadowView.layer.shadowOpacity = 0.25
        songImageShadowView.layer.shadowOffset = CGSize(width: 0, height: 10)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDisplay()
        MediaManager.delegate = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? NotificationViewController {
            vc.imageName = notification.0
            vc.notification = notification.1
        }
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func updateDisplay() {
        guard let currentIndex = MediaManager.currentIndex else { return }
        let song = MediaManager.songs[currentIndex]
        
        songNameLabel.text = song.getName()
        
        let isAdded = LibraryManager.isAddedToLibrary(id: song.id)
        let image = isAdded ? UIImage(systemName: "checkmark") : UIImage(systemName: "plus")
        addedButton.setImage(image, for: .normal)
        
        loadImage()
        updateMediaControls()
    }
    
    func updateMediaControls() {
        playButton.isHidden = MediaManager.isPlaying
        pauseButton.isHidden = !MediaManager.isPlaying
        if MediaManager.isPlaying {
            pullImageView()
        } else {
            pushImageView()
        }
    }
    
    func loadImage() {
        guard let currentIndex = MediaManager.currentIndex else { return }
        let song = MediaManager.songs[currentIndex]
        if song.image_uri != nil {
            let urlString = song.image_uri!
            
            if let data = CacheManager.fetchImage(urlString) {
                DispatchQueue.main.async {
                    self.songImageView.image = UIImage(data: data)
                    self.backgroundImageView.image = UIImage(data: data)
                }
                return
            }
            
            songImageView.image = UIImage(named: "ImageLoading")
            backgroundImageView.image = UIImage(named: "ImageLoading")
            
            if let url = URL(string: urlString) {
                let session = URLSession.shared
                let dataTask = session.dataTask(with: url) { (data, response, error) in
                    if error == nil && data != nil {
                        if song.image_uri! == urlString {
                            CacheManager.saveImage(urlString, data!)
                            DispatchQueue.main.async {
                                self.songImageView.image = UIImage(data: data!)
                                self.backgroundImageView.image = UIImage(data: data!)
                            }
                            
                        }
                    }
                }
                dataTask.resume()
            }
        }
    }
    
    func pushImageView() {
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseOut) {
            self.songImageShadowView.transform = CGAffineTransform(scaleX: 0.8625, y: 0.8625)
        }
    }
    
    func pullImageView() {
        UIView.animate(withDuration: 0.55, delay: 0, usingSpringWithDamping: 0.725, initialSpringVelocity: 2.25, options: .curveEaseOut) {
            self.songImageShadowView.transform = .identity
        }
    }
    
    @IBAction func addTapped(_ sender: Any) {
        guard let currentIndex = MediaManager.currentIndex else { return }
        let song = MediaManager.songs[currentIndex]
        
        let isAdded = LibraryManager.isAddedToLibrary(id: song.id)
        
        if isAdded {
            addedButton.setImage(UIImage(systemName: "plus"), for: .normal)
            LibraryManager.removeFromLibrary(id: song.id)
            notification = ("folder.badge.minus.fill","Removed From Library")
            performSegue(withIdentifier: "presentNotification", sender: self)
        } else {
            addedButton.setImage(UIImage(systemName: "checkmark"), for: .normal)
            LibraryManager.addToLibrary(id: song.id)
            notification = ("folder.badge.plus.fill","Added To Library")
            performSegue(withIdentifier: "presentNotification", sender: self)
        }
    }
}

// MARK: = MediaManagerProtocol Methods
extension MediaViewController: MediaManagerProtocol {
    
    func mediaCurrentTimeChanged(_ currentTime: Float64, _ duration: Float64) {
        let progress = Float((currentTime / duration) * 1000).rounded() / 1000
        
        if progress == 1 {
            forwardAction()
        }
        
        DispatchQueue.main.async {
            self.scrubBar.value = progress
        }
        
        let convertedCurrentTime = convertSecondsToMinutes(Float(currentTime))
        var currentTimeString = "\(convertedCurrentTime.0):"
        if convertedCurrentTime.1 < 10 {
            currentTimeString = "\(currentTimeString)0"
        }
        currentTimeString = "\(currentTimeString)\(convertedCurrentTime.1)"
        currentTimeLabel.text = currentTimeString
        
        let convertedDuration = convertSecondsToMinutes(Float(duration))
        var durationString = "\(convertedDuration.0):"
        if convertedDuration.1 < 10 {
            durationString = "\(durationString)0"
        }
        durationString = "\(durationString)\(convertedDuration.1)"
        durationLabel.text = durationString
    }
    
    func convertSecondsToMinutes(_ seconds: Float) -> (Int, Int) {
        var minutes = 0
        var remainingSeconds = seconds
        while remainingSeconds >= 60 {
            remainingSeconds -= 60
            minutes += 1
        }
        
        if remainingSeconds.isNaN || remainingSeconds < 0 {
            remainingSeconds = 0
        }
        return (minutes, Int(floor(remainingSeconds)))
    }
}

// MARK: - Media Control Methods
extension MediaViewController {
    
    @IBAction func backwardTapped(_ sender: Any) {
        if !MediaManager.isPlaying {
            pullImageView()
        }
        MediaManager.backward()
        updateDisplay()
        playButton.isHidden = true
        pauseButton.isHidden = false
    }
    
    @IBAction func playTapped(_ sender: Any) {
        MediaManager.play()
        playButton.isHidden = true
        pauseButton.isHidden = false
        pullImageView()
    }
    
    @IBAction func pauseTapped(_ sender: Any) {
        MediaManager.pause()
        playButton.isHidden = false
        pauseButton.isHidden = true
        pushImageView()
    }
    
    @IBAction func forwardTapped(_ sender: Any) {
        forwardAction()
    }
    
    func forwardAction() {
        if !MediaManager.isPlaying {
            pullImageView()
        }
        MediaManager.forward()
        updateDisplay()
        playButton.isHidden = true
        pauseButton.isHidden = false
    }
}
