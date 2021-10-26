//
//  ViewController.swift
//  KK Music
//
//  Created by Nolin McFarland on 10/23/21.
//

import UIKit

class SongsViewController: UIViewController {
    
    @IBOutlet weak var songsTableView: UITableView!
    
    @IBOutlet weak var mediaPeak: UIView!
    @IBOutlet weak var mediaPeakBackground: UIView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var mediaPeakBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrubBar: UIProgressView!
    @IBOutlet weak var songImageView: UIImageView!
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var backwardButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    
    @IBOutlet weak var segmentControl: UISegmentedControl!
    var libraryMode = false
    
    var songModel = SongModel()
    
    var notification: (String, String) = ("","")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        songImageView.layer.cornerRadius = 3
        scrubBar.progress = 0.0
        scrubBar.transform = CGAffineTransform(scaleX: 1, y: 2)
        scrubBar.isHidden = false
        hideMediaPeak(animated: false)
        
        songsTableView.delegate = self
        songsTableView.dataSource = self
        
        songModel.delegate = self
        songModel.fetchSongs()
        
        reloadSongs()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSelectedCell()
        updateMediaControls()
        updateMediaPeak()
        MediaManager.delegate = self
        
        self.songsTableView.reloadRows(at: songsTableView.indexPathsForVisibleRows ?? [IndexPath](), with: .none)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? NotificationViewController {
            vc.imageName = notification.0
            vc.notification = notification.1
        }
    }
}

// MARK: - MediaManagerProtocol Methods
extension SongsViewController: MediaManagerProtocol {
    
    func mediaCurrentTimeChanged(_ currentTime: Float64, _ duration: Float64) {
        var progress = Float((currentTime / duration) * 1000).rounded() / 1000
        
        if progress.isNaN {
            progress = 0
        }
        
        if progress == 1 {
            forwardAction()
        }
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.01) {
                self.scrubBar.progress = progress
            }
        }
    }
}

// MARK: - SongModelProtocol Methods
extension SongsViewController: SongModelProtocol {
    
    func songsRetrieved(_ songs: [Song]) {
        MediaManager.songs = songs
        reloadSongs()
    }
    
    func reloadSongs() {
        if MediaManager.songs.count > 0 {
            songsTableView.reloadData()
            songsTableView.isHidden = false
        } else {
            songsTableView.isHidden = true
        }
    }
}

// MARK: - Media Peak Methods
extension SongsViewController {
    
    func hideMediaPeak(animated: Bool) {
        let duration = animated ? 0.25 : 0
        self.mediaPeakBottomConstraint.constant = mediaPeak.frame.height * -1
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
            self.mediaPeak.alpha = 0
            self.mediaPeakBackground.alpha = 0
        }
    }
    
    func showMediaPeak(animated: Bool) {
        let duration = animated ? 0.25 : 0
        self.mediaPeakBottomConstraint.constant = 0
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
            self.mediaPeak.alpha = 1
            self.mediaPeakBackground.alpha = 1
        }
    }
    
    func updateMediaPeak() {
        guard let currentIndex = MediaManager.currentIndex else { return }
        let song = MediaManager.songs[currentIndex]
        songNameLabel.text = song.getName()
        
        let urlString = song.image_uri!
        
        if let data = CacheManager.fetchImage(urlString) {
            DispatchQueue.main.async {
                self.songImageView.image = UIImage(data: data)
                self.backgroundImageView.image = UIImage(data: data)
                self.scrubBar.progressTintColor = self.songImageView.image?.averageColor
            }
        } else {
            songImageView.image = UIImage(named: "ImageLoading")
            if let url = URL(string: urlString) {
                let session = URLSession.shared
                let dataTask = session.dataTask(with: url) { (data, response, error) in
                    if error == nil && data != nil {
                        if song.image_uri! == urlString {
                            CacheManager.saveImage(urlString, data!)
                            DispatchQueue.main.async {
                                self.songImageView.image = UIImage(data: data!)
                                self.backgroundImageView.image = UIImage(data: data!)
                                self.scrubBar.progressTintColor = self.songImageView.image?.averageColor
                            }
                            
                        }
                    }
                }
                dataTask.resume()
            }
        }
        
        showMediaPeak(animated: true)
    }
}

// MARK: - Media Control Methods
extension SongsViewController {
    
    @IBAction func backwardTapped(_ sender: Any) {
        MediaManager.backward()
        updateSelectedCell()
        updateMediaPeak()
        updateMediaControls()
    }
    
    @IBAction func playTapped(_ sender: Any) {
        MediaManager.play()
        updateMediaControls()
    }
    
    @IBAction func pauseTapped(_ sender: Any) {
        MediaManager.pause()
        updateMediaControls()
    }
    
    @IBAction func forwardTapped(_ sender: Any) {
        forwardAction()
    }
    
    func forwardAction() {
        MediaManager.forward()
        updateSelectedCell()
        updateMediaPeak()
        updateMediaControls()
    }
    
    func updateMediaControls() {
        playButton.isHidden = MediaManager.isPlaying
        pauseButton.isHidden = !MediaManager.isPlaying
    }
}

// MARK: - TableView Methods
extension SongsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MediaManager.songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Song Cell", for: indexPath) as! SongTableViewCell
        cell.display(song: MediaManager.songs[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        MediaManager.currentIndex = indexPath.row
        updateMediaPeak()
        MediaManager.play()
        playButton.isHidden = true
        pauseButton.isHidden = false
        updateSelectedCell()
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let song = MediaManager.songs[indexPath.row]
        let isAdded = LibraryManager.isAddedToLibrary(id: song.id)
        
        let title = isAdded ? "Remove" : "Add"
        let item = UIContextualAction(style: .normal, title: title) { contextualAction, sourceView, completed in
            if isAdded {
                LibraryManager.removeFromLibrary(id: song.id)
                self.notification = ("folder.badge.minus.fill","Removed From Library")
            } else {
                LibraryManager.addToLibrary(id: song.id)
                self.notification = ("folder.badge.plus.fill","Added To Library")
            }
            self.performSegue(withIdentifier: "presentNotification", sender: self)
            self.songsTableView.reloadRows(at: [indexPath], with: .automatic)
            completed(true)
        }
        item.backgroundColor = isAdded ? .red : .systemGray3
        
        let swipeActions = UISwipeActionsConfiguration(actions: [item])
        return swipeActions
    }
    
    func updateSelectedCell() {
        for i in 0..<MediaManager.songs.count {
            let cell = songsTableView.cellForRow(at: IndexPath(row: i, section: 0))
            if i == MediaManager.currentIndex {
                cell?.isSelected = true
            } else {
                cell?.isSelected = false
            }
        }
    }
}
