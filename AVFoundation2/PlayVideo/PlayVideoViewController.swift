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
    @IBOutlet weak var navigationView: UIView!
    @IBOutlet weak var sliderView: UIView!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var durationTimeLabel: UILabel!
    @IBOutlet weak var saveVideoButton: UIButton!
    @IBOutlet weak var trimButton: UIButton!
    @IBOutlet weak var musicButton: UIButton!
    
    var cutVideoView: ThumbnailCutVideoView!
    var mutableComposition: AVMutableComposition!
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var originVideo: AVAsset?
    
    var url: URL?
    var isVideoPlaying = false
    var isZoomVideo = false
    var listRate: [Float] = [1, 1.25, 1.5, 1.75, 2, 0.25, 0.5, 0.75]
    var rateNumber: Int = 0
    var isLoop = false
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let videoString = Bundle.main.path(forResource: "SampleVideo1", ofType: "mp4")!
        url = URL(fileURLWithPath: videoString)
        player = AVPlayer(url: url!)
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
    
    @IBAction func saveVideoButtonAction(_ sender: Any) {
        saveVideoButton.isHidden = true
        cutVideoView.isHidden = true
        trimButton.isHidden = false
        
        self.sliderView.isUserInteractionEnabled = true
        self.navigationView.isUserInteractionEnabled = true
        self.sliderView.alpha = 1
        self.navigationView.alpha = 1
        self.videoView.alpha = 1
        
        self.buildComposition()
        self.updatePlayerItem()
    }
    
    func getThumbnailFrom(path: URL) -> UIImage? {
        do {
            let asset = AVURLAsset(url: path , options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 2, timescale: 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)

            return thumbnail
        }
        catch let error {
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Add music
    @IBAction func addMusicForVideoButtonAction(_ sender: UIButton) {
        let musicString = Bundle.main.path(forResource: "SampleAudio1", ofType: "mp3")!
        self.mutableComposition = AVMutableComposition()
        url = URL(fileURLWithPath: musicString)
        let originAsset = AVAsset(url: url!)
        let originVideoTracks = originAsset.tracks
        
        let videoString = Bundle.main.path(forResource: "SampleVideo1", ofType: "mp4")!
        let url2 = URL(fileURLWithPath: videoString)
        originVideo = AVAsset(url: url2)
        
        originVideoTracks.forEach { (track) in
            if track.mediaType == .audio {
                let trackComposition = self.mutableComposition.addMutableTrack(withMediaType: track.mediaType, preferredTrackID: track.trackID)
                try? trackComposition?.insertTimeRange(CMTimeRange(start: CMTime(seconds: 0, preferredTimescale: 1), duration: CMTime(seconds: 60, preferredTimescale: 1)), of: track, at: .zero)
                trackComposition?.scaleTimeRange(CMTimeRange(start: CMTime(seconds: 0, preferredTimescale: 1), duration: CMTime(seconds: 60, preferredTimescale: 1)), toDuration: CMTime(seconds: 25, preferredTimescale: 1))
            }
        }
        let trackCompositionz = self.mutableComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        try? trackCompositionz?.insertTimeRange(CMTimeRange(start: CMTime(seconds: 0, preferredTimescale: 1), duration: originAsset.duration), of: originVideo!.tracks(withMediaType: .video).first!, at: .zero)
        
        let playerItem = AVPlayerItem(asset: self.mutableComposition)
        playerItem.audioTimePitchAlgorithm = .varispeed
        player.replaceCurrentItem(with: playerItem)
    }
    
    @IBAction func filterVideo(_ sender: Any) {
        
    }
    
    
    // MARK: - Trim video
    @IBAction func trimVideoButton(_ sender: Any) {
        
        saveVideoButton.isHidden = false
        trimButton.isHidden = true
        
        // Add CutAudioView
        cutVideoView = ThumbnailCutVideoView(frame: CGRect(x: 40, y: 10, width: self.view.frame.width - 80, height: 62), fileImage: getThumbnailFrom(path: url!)!)
        cutVideoView.backgroundColor = .clear
        cutVideoView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(cutVideoView)

        cutVideoView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 40).isActive = true
        cutVideoView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -40).isActive = true
        cutVideoView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 100).isActive = true
        cutVideoView.heightAnchor.constraint(equalToConstant: 62).isActive = true

        // updown alpha
        self.sliderView.isUserInteractionEnabled = false
        self.navigationView.isUserInteractionEnabled = false
        self.sliderView.alpha = 0.1
        self.navigationView.alpha = 0.1
        self.videoView.alpha = 0.1
    }
    
    func buildComposition() {
        self.mutableComposition = AVMutableComposition()
        
        originVideo = AVAsset(url: url! as URL)
        let originVideoTracks = originVideo!.tracks
        
        let trimRange = currentTrimRange()
        originVideoTracks.forEach { (originVideoTrack) in
            let track = self.mutableComposition.addMutableTrack(withMediaType: originVideoTrack.mediaType, preferredTrackID: originVideoTrack.trackID)
            try? track?.insertTimeRange(CMTimeRange(start: trimRange.start + originVideoTrack.timeRange.start, duration: trimRange.duration), of: originVideoTrack, at: .zero)
            track?.scaleTimeRange(CMTimeRange(start: CMTime(seconds: 0, preferredTimescale: 1), duration: CMTime(seconds: 60, preferredTimescale: 1)), toDuration: CMTime(seconds: 25, preferredTimescale: 1))
        }
    }
    
    private func currentTrimRange() -> CMTimeRange {
        let startTime = CGFloat(cutVideoView.leftStartTime)
        let endTime = CGFloat(cutVideoView.rightEndTime)
        let duration = player.currentItem?.duration.seconds
        return CMTimeRange(start: CMTime(value: CMTimeValue(startTime * CGFloat(duration!) * 1000), timescale: 1000), end: CMTime(value: CMTimeValue(endTime * CGFloat(duration!) * 1000), timescale: 1000))
    }
    
    func updatePlayerItem() {
        if let currentItem = self.player.currentItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: currentItem)
        }
        
        let playerItem = AVPlayerItem(asset: self.mutableComposition)
        playerItem.audioTimePitchAlgorithm = .varispeed
        self.player.replaceCurrentItem(with: playerItem)
        durationTimeLabel.text = getTimeString(from: player.currentItem!.duration)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEndTime(_:)), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    @objc func playerItemDidPlayToEndTime(_ notification: Notification) {
        self.player.pause()
        self.player.seek(to: CMTime.zero, toleranceBefore: .zero, toleranceAfter: .zero)
    }
}



