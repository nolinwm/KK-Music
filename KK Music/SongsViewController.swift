//
//  ViewController.swift
//  KK Music
//
//  Created by Nolin McFarland on 10/23/21.
//

import UIKit

class SongsViewController: UIViewController {
    
    @IBOutlet weak var songsTableView: UITableView!
    @IBOutlet weak var loadingLabel: UILabel!
    
    @IBOutlet weak var mediaPeak: UIView!
    @IBOutlet weak var mediaPeakBackground: UIView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var mediaPeakBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var scrubBar: UIProgressView!
    @IBOutlet weak var songImageView: UIImageView!
    @IBOutlet weak var songNameLabel: UILabel!
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    
    var songModel = SongModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        songImageView.layer.cornerRadius = 3
        scrubBar.progress = 0.0
        scrubBar.transform = CGAffineTransform(scaleX: 1, y: 2)
        hideMediaPeak(animated: false)
        
        songsTableView.delegate = self
        songsTableView.dataSource = self
        
        songModel.delegate = self
        songModel.fetchSongs()
        
        reloadSongs()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        MediaManager.delegate = self
        
        self.songsTableView.reloadRows(at: songsTableView.indexPathsForVisibleRows ?? [IndexPath](), with: .none)
        updateMediaControls()
        updateMediaPeak()
        updateSelectedCell()
    }
}

// MARK: - SongModelProtocol Methods
extension SongsViewController: SongModelProtocol {
    
    func songsRetrieved(_ songs: [Song]) {
        MediaManager.songs = songs
        reloadSongs()
    }
    
    func reloadSongs() {
        loadingLabel.isHidden = (MediaManager.songs.count > 0)
        songsTableView.isHidden = (MediaManager.songs.count == 0)
        if MediaManager.songs.count > 0 {
            songsTableView.reloadData()
        }
    }
}

// MARK: - Media Peak Methods
extension SongsViewController: MediaManagerDelegate {
    
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
        guard let currentSong = MediaManager.currentSong else { return }
        songNameLabel.text = currentSong.getName()
        
        let urlString = currentSong.image_uri!
        
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
                        if currentSong.image_uri! == urlString {
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
    
    func updateMediaControls() {
        DispatchQueue.main.async {
            self.playButton.isHidden = MediaManager.isPlaying
            self.pauseButton.isHidden = !MediaManager.isPlaying
        }
    }
    
    func mediaStatusChanged() {
        updateMediaControls()
        updateMediaPeak()
        updateSelectedCell()
    }
    
    func mediaTimeChanged() {
        DispatchQueue.main.async {
            self.scrubBar.isHidden = (MediaManager.currentSongProgress == 0)
            self.scrubBar.setProgress(MediaManager.currentSongProgress, animated: false)
        }
    }
}

// MARK: - Media Control Methods
extension SongsViewController {
    
    @IBAction func playTapped(_ sender: Any) {
        MediaManager.play()
    }
    
    @IBAction func pauseTapped(_ sender: Any) {
        MediaManager.pause()
    }
    
    @IBAction func forwardTapped(_ sender: Any) {
        forwardAction()
    }
    
    func forwardAction() {
        MediaManager.forward()
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
        MediaManager.play(indexPath.row)
        updateMediaPeak()
        updateMediaControls()
        updateSelectedCell()
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let song = MediaManager.songs[indexPath.row]
        let isAdded = LibraryManager.isAddedToLibrary(id: song.id)
        
        let item = UIContextualAction(style: .normal, title: title) { contextualAction, sourceView, completed in
            if isAdded {
                LibraryManager.removeFromLibrary(id: song.id)
            } else {
                LibraryManager.addToLibrary(id: song.id)
            }
            self.songsTableView.reloadRows(at: [indexPath], with: .automatic)
            self.updateSelectedCell()
            completed(true)
        }
        item.backgroundColor = isAdded ? .red : .systemGray3
        item.image = isAdded ? UIImage(systemName: "trash.fill") : UIImage(systemName: "plus")
        
        let swipeActions = UISwipeActionsConfiguration(actions: [item])
        return swipeActions
    }
    
    func updateSelectedCell() {
        if let currentSongIndex = MediaManager.currentSongIndex {
            let indexPath = IndexPath(row: currentSongIndex, section: 0)
            songsTableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        } else {
            songsTableView.selectRow(at: nil, animated: false, scrollPosition: .none)
        }
    }
}
