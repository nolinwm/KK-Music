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
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    
    var songModel = SongModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        stylizeViewController()
        transitionMediaPeak(hidden: true, animated: false)
        
        songsTableView.delegate = self
        songsTableView.dataSource = self

        songModel.delegate = self
        songModel.fetchSongs()
        
        reloadSongs()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let mediaVC = segue.destination as? MediaViewController {
            mediaVC.delegate = self
        }
    }
    
    func stylizeViewController() {
        songImageView.layer.cornerRadius = 3
        scrubBar.progress = 0.0
        scrubBar.transform = CGAffineTransform(scaleX: 1, y: 2)
    }
    
    func refreshView() {
        MediaManager.delegate = self
        smartReloadVisibleRows()
        updateMediaControls()
        updateMediaPeak()
        updateSelectedCell()
    }
}

// MARK: - MediaViewDelegate Methods
extension SongsViewController: MediaViewDelegate {
    
    func mediaViewWillDismiss() {
        refreshView()
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
            DispatchQueue.main.async {
                self.songsTableView.reloadData()
            }
        }
    }
}

// MARK: - Media Peak Methods
extension SongsViewController: MediaManagerDelegate {
    
    func transitionMediaPeak(hidden: Bool, animated: Bool) {
        let duration = animated ? 0.25 : 0
        self.mediaPeakBottomConstraint.constant = hidden ? (mediaPeak.frame.height * -1) : 0
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
            self.mediaPeak.alpha = hidden ? 0 : 1
            self.mediaPeakBackground.alpha = hidden ? 0 : 1
        }
    }
    
    func updateMediaPeak() {
        guard let currentSong = MediaManager.currentSong else { return }
        songNameLabel.text = currentSong.getName()
        
        let urlString = currentSong.image_uri!
        if let data = CacheManager.fetchImage(urlString) {
            self.songImageView.image = UIImage(data: data)
            self.backgroundImageView.image = UIImage(data: data)
            self.scrubBar.progressTintColor = self.songImageView.image?.averageColor
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
        
        transitionMediaPeak(hidden: false, animated: true)
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
        MediaManager.forward()
    }
}

// MARK: - TableView Methods
extension SongsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MediaManager.songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Song Cell", for: indexPath) as? SongTableViewCell else { return UITableViewCell() }
        cell.displayCell(song: MediaManager.songs[indexPath.row])
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
            completed(true)
        }
        item.backgroundColor = isAdded ? .red : .systemGray3
        item.image = isAdded ? UIImage(systemName: "trash.fill") : UIImage(systemName: "plus")
        
        let swipeActions = UISwipeActionsConfiguration(actions: [item])
        return swipeActions
    }
    
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        updateSelectedCell()
    }
    
    func smartReloadVisibleRows() {
        guard let indexPathsForVisibleRows = songsTableView.indexPathsForVisibleRows else { return }
        var indexPathsToReload = [IndexPath]()
        for indexPath in indexPathsForVisibleRows {
            if let cell = songsTableView.cellForRow(at: indexPath) as? SongTableViewCell {
                if let song = cell.song {
                    // Image view isHidden should never match isAddedToLibrary, need to reload cell
                    if cell.addedImageView.isHidden == LibraryManager.isAddedToLibrary(id: song.id) {
                        indexPathsToReload.append(indexPath)
                    }
                }
            }
        }
        if indexPathsToReload.count > 0 {
            songsTableView.reloadRows(at: indexPathsToReload, with: .none)
        }
    }
    
    func updateSelectedCell() {
        if let currentSongIndex = MediaManager.currentSongIndex {
            let indexPath = IndexPath(row: currentSongIndex, section: 0)
            songsTableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        } else {
            songsTableView.selectRow(at: nil, animated: false, scrollPosition: .none)
        }
    }
}
