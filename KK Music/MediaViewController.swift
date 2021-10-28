//
//  MediaViewController.swift
//  KK Music
//
//  Created by Nolin McFarland on 10/24/21.
//

import UIKit

class MediaViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var swipeToCloseBar: UIView!
    
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
    
    var isScrubbing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        stylizeViewController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MediaManager.delegate = self
        updateMediaView()
        beginAnimatingBackground()
        
        prepareForPresentAnimation()
        presentAnimation()
    }
    
    func stylizeViewController() {
        scrubBar.setThumbImage(UIImage(systemName: "circle.fill"), for: .normal)
        
        swipeToCloseBar.layer.cornerRadius = 3
        
        songImageView.layer.cornerRadius = 12
        songImageShadowView.layer.cornerRadius = 12
        songImageShadowView.layer.shadowColor = UIColor.black.cgColor
        songImageShadowView.layer.shadowRadius = 15
        songImageShadowView.layer.shadowOpacity = 0.25
        songImageShadowView.layer.shadowOffset = CGSize(width: 0, height: 10)
    }
    
    func beginAnimatingBackground() {
        UIView.animate(withDuration: 10, delay: 0, options: [.repeat, .autoreverse]) {
            self.backgroundImageView.transform = CGAffineTransform(
                scaleX: 3.75,
                y: 2
            )
            self.backgroundImageView.alpha = 0.85
        }
    }
    
    @IBAction func dismissTapped(_ sender: Any) {
        dismissAnimation()
    }
    
    @IBAction func addTapped(_ sender: Any) {
        guard let currentSong = MediaManager.currentSong else { return }
        
        let isAdded = LibraryManager.isAddedToLibrary(id: currentSong.id)
        let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
        
        if isAdded {
            LibraryManager.removeFromLibrary(id: currentSong.id)
            hapticFeedback.impactOccurred()
        } else {
            LibraryManager.addToLibrary(id: currentSong.id)
            hapticFeedback.impactOccurred()
        }
        
        updateMediaControls()
    }
    
    @IBAction func didStartScrubbing(_ sender: Any) {
        isScrubbing = true
    }
    
    @IBAction func scrubTouchUpInside(_ sender: Any) {
        didEndScrubbing()
    }
    
    @IBAction func scrubTouchUpOutside(_ sender: Any) {
        didEndScrubbing()
    }
    
    func didEndScrubbing() {
        isScrubbing = false
        let progress = scrubBar.value
        MediaManager.scrub(progress)
    }
}

// MARK: - Present and Dismiss Animation Methods
extension MediaViewController {
    
    func prepareForPresentAnimation() {
        containerView.transform = CGAffineTransform(
            translationX: 0,
            y: containerView.frame.height
        )
        containerView.layer.cornerRadius = 40
    }
    
    func presentAnimation() {
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseOut) {
            self.containerView.transform = .identity
        }
        UIView.animate(withDuration: 0.175, delay: 0.175, options: .curveEaseOut) {
            self.containerView.layer.cornerRadius = 0
        }
    }
    
    func dismissAnimation() {
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseOut) {
            self.containerView.transform = CGAffineTransform(
                translationX: 0,
                y: self.containerView.frame.height
            )
        } completion: { complete in
            self.dismiss(animated: false, completion: nil)
        }
        UIView.animate(withDuration: 0.175, delay: 0, options: .curveEaseOut) {
            self.containerView.layer.cornerRadius = 40
        }
    }
}

// MARK: - MediaManagerDelegate Methods
extension MediaViewController: MediaManagerDelegate {
    
    func mediaStatusChanged() {
        updateMediaView()
    }
    
    func mediaTimeChanged() {
        guard MediaManager.currentSongDuration > 0 else {
            DispatchQueue.main.async {
                self.scrubBar.value = 0
                self.currentTimeLabel.text = "0:00"
                self.durationLabel.text = "-0:00"
            }
            return
        }
        
        let currentSongTime = isScrubbing ? Int(Float(MediaManager.currentSongDuration) * scrubBar.value) : MediaManager.currentSongTime
        let currentSongTimeString = convertSecondsToTimeString(seconds: currentSongTime)
        let currentSongRemainingDurationString = convertSecondsToTimeString(seconds: MediaManager.currentSongDuration - currentSongTime)

        DispatchQueue.main.async {
            if !self.isScrubbing {
                self.scrubBar.setValue(MediaManager.currentSongProgress, animated: false)
            }
            self.currentTimeLabel.text = currentSongTimeString
            self.durationLabel.text = "-\(currentSongRemainingDurationString)"
        }
    }
    
    func convertSecondsToTimeString(seconds: Int) -> String {
        var remainingSeconds = seconds
        var minutes = 0
        
        while remainingSeconds >= 60 {
            remainingSeconds -= 60
            minutes += 1
        }
        
        var timeString = "\(minutes):"
        if remainingSeconds < 10 {
            timeString = "\(timeString)0"
        }
        timeString = "\(timeString)\(remainingSeconds)"
        
        return timeString
    }
}

// MARK: - Media View Methods
extension MediaViewController {
    
    func updateMediaView() {
        guard let currentSong = MediaManager.currentSong else { return }
        
        songNameLabel.text = currentSong.getName()
        loadMediaImage()
        
        updateMediaControls()
    }
    
    func updateMediaControls() {
        guard let currentSong = MediaManager.currentSong else { return }
        
        playButton.isHidden = MediaManager.isPlaying
        pauseButton.isHidden = !MediaManager.isPlaying
        
        if MediaManager.isPlaying {
            pullImageView()
        } else {
            pushImageView()
        }
        
        let isAdded = LibraryManager.isAddedToLibrary(id: currentSong.id)
        let image = isAdded ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "plus")
        DispatchQueue.main.async {
            self.addedButton.setImage(image, for: .normal)
        }
    }
    
    func loadMediaImage() {
        guard let currentSong = MediaManager.currentSong else { return }
        
        if currentSong.image_uri != nil {
            let urlString = currentSong.image_uri!
            
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
                        if currentSong.image_uri! == urlString {
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
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.275, delay: 0, options: .curveEaseOut) {
                self.songImageShadowView.transform = CGAffineTransform(scaleX: 0.825, y: 0.825)
                self.songImageView.layer.shadowOpacity = (0.25 * 0.825)
            }
        }
    }
    
    func pullImageView() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.725, initialSpringVelocity: 2.75, options: .curveEaseOut) {
                self.songImageShadowView.transform = .identity
                self.songImageView.layer.shadowOpacity = 0.25
            }
        }
    }
}

// MARK: - Media Control Methods
extension MediaViewController {
    
    @IBAction func backwardTapped(_ sender: Any) {
        if !MediaManager.isPlaying {
            pullImageView()
        }
        MediaManager.backward()
    }
    
    @IBAction func playTapped(_ sender: Any) {
        MediaManager.play()
        pullImageView()
    }
    
    @IBAction func pauseTapped(_ sender: Any) {
        MediaManager.pause()
        pushImageView()
    }
    
    @IBAction func forwardTapped(_ sender: Any) {
        if !MediaManager.isPlaying {
            pullImageView()
        }
        MediaManager.forward()
    }
}
