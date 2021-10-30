//
//  MediaViewController.swift
//  KK Music
//
//  Created by Nolin McFarland on 10/24/21.
//

import UIKit

protocol MediaViewDelegate {
    func mediaViewWillDismiss()
}

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
    var delegate: MediaViewDelegate?
    
    // Used for tracking the swipe to close full screen translation
    var containerViewTranslation = CGPoint(x: 0, y: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        stylizeViewController()
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MediaManager.delegate = self
        updateMediaView()
        
        beginAnimatingBackground()
        animatePresent()
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
        // Animate the background image resizing to give impression of a live background
        UIView.animate(withDuration: 30, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut]) {
            self.backgroundImageView.transform = CGAffineTransform(scaleX: 4, y: 2)
            self.backgroundImageView.alpha = 0.85
        }
    }
    
    @IBAction func dismissTapped(_ sender: Any) {
        animateDismiss()
    }
    
    @IBAction func addTapped(_ sender: Any) {
        guard let currentSong = MediaManager.currentSong else { return }
        let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
        
        let isAdded = LibraryManager.isAddedToLibrary(id: currentSong.id)
        if isAdded {
            LibraryManager.removeFromLibrary(id: currentSong.id)
        } else {
            LibraryManager.addToLibrary(id: currentSong.id)
        }
        
        hapticFeedback.impactOccurred()
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
        MediaManager.scrub(scrubBar.value)
    }
}

// MARK: - Present and Dismiss Animation Methods
extension MediaViewController {
    
    @objc func handlePanGesture(sender: UIPanGestureRecognizer) {
        switch sender.state {
        case.changed:
            // Animate to the new finger position and adjust the corner radius accordingly.
            containerViewTranslation = sender.translation(in: view)
            UIView.animate(withDuration: 0.075, delay: 0) {
                self.containerView.transform = CGAffineTransform(translationX: 0, y: max(0, self.containerViewTranslation.y))
            }
            containerView.layer.cornerRadius = min((containerViewTranslation.y / 3), 40)
            break
        case .ended:
            // Once finger is lifted, determine if it should bounce back up or dismiss.
            if self.containerViewTranslation.y < (view.frame.height / 3.5) {
                UIView.animate(withDuration: self.containerViewTranslation.y / view.frame.height, delay: 0) {
                    self.containerView.transform = .identity
                    self.containerView.layer.cornerRadius = 0
                }
            } else {
                view.isUserInteractionEnabled = false
                animateDismiss()
            }
            break
        default:
            break
        }
    }
    
    func animatePresent() {
        // Prepare
        containerView.transform = CGAffineTransform(
            translationX: 0,
            y: containerView.frame.height
        )
        containerView.layer.cornerRadius = 40
        
        // Animate
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseInOut) {
            self.containerView.transform = .identity
        }
        UIView.animate(withDuration: 0.175, delay: 0.175, options: .curveEaseOut) {
            self.containerView.layer.cornerRadius = 0
        }
    }
    
    func animateDismiss() {
        delegate?.mediaViewWillDismiss()
        UIView.animate(withDuration: 0.28, delay: 0, options: .curveEaseOut) {
            self.containerView.transform = CGAffineTransform(
                translationX: 0,
                y: self.containerView.frame.height
            )
        } completion: { complete in
            self.dismiss(animated: false, completion: nil)
        }
        UIView.animate(withDuration: 0.145, delay: 0, options: .curveEaseOut) {
            self.containerView.layer.cornerRadius = 40
        }
    }
}

// MARK: - MediaManagerDelegate Methods
extension MediaViewController: MediaManagerDelegate {
    
    func mediaStatusChanged() {
        DispatchQueue.main.async {
            self.updateMediaView()
        }
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
            // Append a 0 if there is less than 10 seconds
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
        updateMediaControls()
        loadMediaImage()
    }
    
    func updateMediaControls() {
        guard let currentSong = MediaManager.currentSong else { return }
        
        playButton.isHidden = MediaManager.isPlaying
        pauseButton.isHidden = !MediaManager.isPlaying
        
        if MediaManager.isPlaying {
            animatePullImageView()
        } else {
            animatePushImageView()
        }
        
        let isAdded = LibraryManager.isAddedToLibrary(id: currentSong.id)
        let image = isAdded ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "plus")
        self.addedButton.setImage(image, for: .normal)
    }
    
    func loadMediaImage() {
        guard let currentSong = MediaManager.currentSong else { return }
        
        if currentSong.image_uri != nil {
            let urlString = currentSong.image_uri!
            
            if let data = CacheManager.fetchImage(urlString) {
                self.songImageView.image = UIImage(data: data)
                self.backgroundImageView.image = UIImage(data: data)
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
    
    func animatePushImageView() {
        UIView.animate(withDuration: 0.225, delay: 0, options: .curveEaseOut) {
            self.songImageShadowView.transform = CGAffineTransform(scaleX: 0.825, y: 0.825)
            self.songImageShadowView.layer.shadowOpacity = 0.175
        }
    }
    
    func animatePullImageView() {
        UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.725, initialSpringVelocity: 2.75, options: .curveEaseOut) {
            self.songImageShadowView.transform = .identity
            self.songImageShadowView.layer.shadowOpacity = 0.25
        }
    }
}

// MARK: - Media Control Methods
extension MediaViewController {
    
    @IBAction func backwardTapped(_ sender: Any) {
        MediaManager.backward()
    }
    
    @IBAction func playTapped(_ sender: Any) {
        MediaManager.play()
    }
    
    @IBAction func pauseTapped(_ sender: Any) {
        MediaManager.pause()
    }
    
    @IBAction func forwardTapped(_ sender: Any) {
        MediaManager.forward()
    }
}
