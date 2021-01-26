//
//  PlayVideoViewController.swift
//  AVFoundation2
//
//  Created by Manh Nguyen Ngoc on 25/01/2021.
//

import UIKit
import AVFoundation

class PlayVideoViewController: UIViewController {
    
    // MARK: - UI + Property
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var durationTimeLabel: UILabel!
    @IBOutlet weak var thumbnailView: UIImageView!
    
    var composition: AVMutableComposition!
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    
    var isVideoPlaying = false
    var isZoomVideo = false
    var listRate: [Float] = [1, 1.25, 1.5, 1.75, 2, 0.25, 0.5, 0.75]
    var rateNumber: Int = 0
    var isLoop = false
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let videoString = Bundle.main.path(forResource: "SampleVideo1", ofType: "mp4")!
        let url = URL(fileURLWithPath: videoString)
        player = AVPlayer(url: url)
        player.currentItem?.addObserver(self, forKeyPath: "duration", options: [.new, .initial], context: nil)
        addTimeObserver()
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        videoView.layer.addSublayer(playerLayer)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = videoView.bounds
    }
    
    func addTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        print(interval)
        let mainQueue = DispatchQueue.main
        _ = player.addPeriodicTimeObserver(forInterval: interval, queue: mainQueue, using: { [weak self] time in
            guard let currentItem = self?.player.currentItem else {return}
            self?.timeSlider.maximumValue = Float(currentItem.duration.seconds)
            self?.timeSlider.minimumValue = 0
            self?.timeSlider.value = Float(currentItem.currentTime().seconds)
            self?.currentTimeLabel.text = self!.getTimeString(from: currentItem.currentTime())
        })
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "duration", let durationTime = player.currentItem?.duration.seconds, durationTime > 0.0 {
            durationTimeLabel.text = getTimeString(from: player.currentItem!.duration)
        }
    }
    
    func getTimeString(from time: CMTime) -> String {
        let totalSeconds = CMTimeGetSeconds(time)
        let hour = Int(totalSeconds / 3600)
        let minutes = Int(totalSeconds / 60) % 60
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        if hour > 0 {
            return String(format: "%i:%02i:%02i", arguments: [hour, minutes, seconds])
        }
        else {
            return String(format: "%02i:%02i", arguments: [minutes, seconds])
        }
    }
    
    
    // MARK: - Button Action Video
    @IBAction func playPressed(_ sender: UIButton) {
        if isVideoPlaying {
            player.pause()
            sender.setTitle("Play", for: .normal)
        }
        else {
            player.play()
            sender.setTitle("Pause", for: .normal)
        }
        isVideoPlaying = !isVideoPlaying
    }
    
    @IBAction func backwardPressed(_ sender: Any) {
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = max(0, currentTime - 5.0)
        let time: CMTime = CMTimeMake(value: Int64(newTime * 1000), timescale: 1000)
        player.seek(to: time)
    }
    
    @IBAction func forwardPressed(_ sender: Any) {
        guard let duration = player.currentItem?.duration else {return}
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = currentTime + 5.0
        if newTime < CMTimeGetSeconds(duration) - 5.0 {
            let time: CMTime = CMTimeMake(value: Int64(newTime * 1000), timescale: 1000)
            player.seek(to: time)
        }
    }
    
    @IBAction func zoomVideo(_ sender: Any) {
        isZoomVideo = !isZoomVideo
        if isZoomVideo {
            playerLayer.videoGravity = .resizeAspectFill
        }
        else {
            playerLayer.videoGravity = .resizeAspect
        }
    }
    
    @IBAction func mutePressed(_ sender: UIButton) {
        if player.isMuted {
            sender.setImage(UIImage(named: "speaker"), for: .normal)
        }
        else {
            sender.setImage(UIImage(named: "mute"), for: .normal)
        }
        player.isMuted = !player.isMuted
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        player.seek(to: CMTimeMake(value: Int64(Int(sender.value * 1000)), timescale: 1000))
    }
    
    @IBAction func changeSpeed(_ sender: UIButton) {
        rateNumber += 1
        rateNumber = rateNumber % listRate.count
        player.rate = listRate[rateNumber]
        sender.setTitle("x\(player.rate)", for: .normal)
    }
    
    @IBAction func loopVideo(_ sender: UIButton) {
        NotificationCenter.default.addObserver(self, selector: #selector(doingWhenPlayingDone), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        isLoop = !isLoop
        if isLoop {
            sender.setBackgroundImage(UIImage(named: "looped"), for: .normal)
        }
        else {
            sender.setBackgroundImage(UIImage(named: "loop"), for: .normal)
        }
    }
    
    @objc func doingWhenPlayingDone() {
        if isLoop {
            player.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
            player.playImmediately(atRate: listRate[rateNumber])
            player.play()
        }
    }
    
    // MARK: - Trim video
    @IBAction func trimVideoButton(_ sender: Any) {
        self.settingComposition()
        self.updatePlayerItem()
    }
    
    func settingComposition() {
        self.composition = AVMutableComposition()
        
        let videoString = Bundle.main.path(forResource: "SampleVideo1", ofType: "mp4")!
        let url = URL(fileURLWithPath: videoString)
        let originAsset = AVAsset(url: url as URL)
        let originVideoTracks = originAsset.tracks(withMediaType: .video)
        
        let trimRange = currentTrimRange()
        originVideoTracks.forEach { (originVideoTrack) in
            let track = self.composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            try? track?.insertTimeRange(CMTimeRange(start: trimRange.start + originVideoTrack.timeRange.start, duration: trimRange.duration), of: originVideoTrack, at: .zero)
        }
    }
    
    private func currentTrimRange() -> CMTimeRange {
        //let trimRange = self.trimView.trimRange
        //let asset = AVAsset(url: sourceURL1 as URL)
        //let duration = asset.duration.seconds
        return CMTimeRange(start: CMTime(value: CMTimeValue(0.9 * CGFloat(120) * 1000), timescale: 1000), end: CMTime(value: CMTimeValue(1 * CGFloat(120) * 1000), timescale: 1000))
    }
    
    func updatePlayerItem() {
        if let currentItem = self.player.currentItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: currentItem)
        }
        
        let playerItem = AVPlayerItem(asset: self.composition)
        self.player.replaceCurrentItem(with: playerItem)
        durationTimeLabel.text = getTimeString(from: player.currentItem!.duration)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEndTime(_:)), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    @objc func playerItemDidPlayToEndTime(_ notification: Notification) {
        //let currentTrimRange = self.currentTrimRange()
        self.player.pause()
        self.player.seek(to: CMTime.zero, toleranceBefore: .zero, toleranceAfter: .zero)
        //self.trimView.currentTime = CGFloat(currentTrimRange.start.seconds)
    }
}
