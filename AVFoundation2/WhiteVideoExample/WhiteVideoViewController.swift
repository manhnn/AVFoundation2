//
//  WhiteVideoViewController.swift
//  AVFoundation2
//  ReCode develop from DrakVideoExample
//  Created by Manh Nguyen Ngoc on 02/02/2021.
//

import UIKit
import AVFoundation

enum RotationVideoType: Int {
    case portrait = 0
    case landscapeLeft = 1
    case upsideDown = 2
    case landscapeRight = 3
}

enum FilterVideoType: Int {
    case ciGaussianBlur = 0
    case ciBumpDistortion = 1
    case ciColorClamp = 2
    case ciPhotoEffectMono = 3
}

class WhiteVideoViewController: UIViewController {

    // MARK: - UI
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var navigationView: UIView!
    @IBOutlet weak var sliderView: UIView!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var timeStartLabel: UILabel!
    @IBOutlet weak var timeDurationLabel: UILabel!
    @IBOutlet weak var saveVideoButton: UIButton!
    @IBOutlet weak var trimButton: UIButton!
    
    
    // MARK: - Property
    var cutVideoView: ThumbnailCutVideoView!
    var player: AVPlayer!
    var playerItem: AVPlayerItem!
    var playerLayer: AVPlayerLayer!
    var originAssetVideo: AVAsset!
    var mutableComposition: AVMutableComposition!
    
    var isPlayingVideo = false
    var isLoop = false
    var listRate: [Float] = [1, 1.25, 1.5, 1.75, 2, 0.25, 0.5, 0.75]
    var rateIndex: Int = 0
    var rotationVideoIndex: Int = 0
    var filterVideoIndex: Int = 0
    
    // MARK: - Method
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupVideoBeforePlay()
        updateTimeInSlider()
        
    }
    
    func setupVideoBeforePlay() {
        mutableComposition = AVMutableComposition()
        originAssetVideo = AVAsset(url: URL(fileURLWithPath: Bundle.main.path(forResource: "VideoExample1", ofType: "mp4")!))
        player = AVPlayer(url: URL(fileURLWithPath: Bundle.main.path(forResource: "VideoExample1", ofType: "mp4")!))
        player.currentItem?.addObserver(self, forKeyPath: "duration", options: [.new, .initial], context: nil)
        playerItem = player.currentItem
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        videoView.layer.addSublayer(playerLayer)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = videoView.bounds
    }
    
    func updateTimeInSlider() {
        // moi 0.45 second giay thi se update lai frame 1 lan de quan sat
        let interval = CMTime(seconds: 0.45, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        _ = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { [weak self] time in
            guard let currentItem = self!.player.currentItem else {return}
            self!.timeSlider.maximumValue = Float(currentItem.duration.seconds)
            self!.timeSlider.minimumValue = 0
            self!.timeSlider.value = Float(currentItem.currentTime().seconds)
            self!.timeStartLabel.text = String(currentItem.currentTime().seconds)
        })
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "duration", (player.currentItem?.duration.seconds)! > 0.0 {
            timeDurationLabel.text = String((player.currentItem?.duration.seconds)!)
        }
    }
    
    // MARK: - Button Controller Video
    @IBAction func changeValueSlider(_ sender: UISlider) {
        player.seek(to: CMTimeMake(value: Int64(sender.value * 1000), timescale: 1000))
    }
    
    @IBAction func playVideoPressed(_ sender: UIButton) {
        isPlayingVideo = !isPlayingVideo
        
        if isPlayingVideo {
            sender.setTitle("Pause", for: .normal)
            player.play()
        }
        else {
            sender.setTitle("Play", for: .normal)
            player.pause()
        }
    }
    
    @IBAction func backwardVIdeoPressed(_ sender: Any) {
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = max(0, currentTime - 5.0)
        player.seek(to: CMTimeMake(value: Int64(newTime * 1000), timescale: 1000))
    }
    
    @IBAction func forwardVideoPressed(_ sender: Any) {
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = currentTime + 5.0
        if newTime < CMTimeGetSeconds(player.currentItem!.duration) - 5.0 {
            player.seek(to: CMTimeMake(value: Int64(newTime * 1000), timescale: 1000))
        }
    }
    
    @IBAction func mutePressed(_ sender: UIButton) {
        player.isMuted = !player.isMuted
        if player.isMuted {
            sender.setBackgroundImage(UIImage(named: "mute"), for: .normal)
        }
        else {
            sender.setBackgroundImage(UIImage(named: "speaker"), for: .normal)
        }
    }
    
    @IBAction func changeRatePressed(_ sender: UIButton) {
        rateIndex += 1
        rateIndex = rateIndex % listRate.count
        player.rate = listRate[rateIndex]
        sender.setTitle("x\(player.rate)", for: .normal)
    }
    
    @IBAction func loopPressed(_ sender: UIButton) {
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
            player.seek(to: CMTime(seconds: 0, preferredTimescale: 1000))
            player.playImmediately(atRate: listRate[rateIndex])
            player.play()
        }
    }
    
    @IBAction func changeDrakMode(_ sender: Any) {
        let viewControllerDrak = PlayVideoViewController()
        navigationController?.pushViewController(viewControllerDrak, animated: true)
    }
    
    
    // MARK: - Rotation Video
    @IBAction func rotationPressed(_ sender: Any) {
        rotationVideoIndex = (rotationVideoIndex + 1) % 4
                
        mutableComposition = AVMutableComposition()
        
        originAssetVideo.tracks.forEach { track in
            let trackComposition = mutableComposition.addMutableTrack(withMediaType: track.mediaType, preferredTrackID: 0)
            try? trackComposition?.insertTimeRange(track.timeRange, of: track, at: .zero)
            trackComposition?.preferredTransform = track.preferredTransform
        }
        
        let ratio = mutableComposition.naturalSize.height / mutableComposition.naturalSize.width
        
        let tranformer = AVMutableVideoCompositionLayerInstruction.init(assetTrack: mutableComposition.tracks(withMediaType: .video).first!)
        var tranform1 = CGAffineTransform()
        
        if rotationVideoIndex == RotationVideoType.landscapeLeft.rawValue {
            tranform1 = CGAffineTransform(rotationAngle: .pi / 2).translatedBy(x: 0, y: -mutableComposition.naturalSize.width * ratio)
        }
        else if rotationVideoIndex == RotationVideoType.upsideDown.rawValue {
            tranform1 = CGAffineTransform(rotationAngle: .pi).translatedBy(x: -mutableComposition.naturalSize.width, y: -mutableComposition.naturalSize.height)
        }
        else if rotationVideoIndex == RotationVideoType.landscapeRight.rawValue {
            tranform1 = CGAffineTransform(rotationAngle: .pi * 1.5).translatedBy(x: -mutableComposition.naturalSize.height / ratio, y: 0)
        }
        else {
            tranform1 = CGAffineTransform(translationX: 0, y: 0.001)
        }
        
        
        tranformer.setTransform(tranform1, at: .zero)
        
        let layerInstruction = AVMutableVideoCompositionInstruction.init()
        layerInstruction.timeRange = CMTimeRangeMake(start: .zero, duration: mutableComposition.duration)
        layerInstruction.layerInstructions = [tranformer]
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTime(value: 1, timescale: 1000)
        videoComposition.instructions = [layerInstruction]
        
        if rotationVideoIndex == RotationVideoType.landscapeLeft.rawValue || rotationVideoIndex == RotationVideoType.landscapeRight.rawValue {
            videoComposition.renderSize = CGSize(width: mutableComposition.naturalSize.height, height: mutableComposition.naturalSize.width)
        }
        else { // rotationIndex == RotationType.upsideDown.rawValue || rotationIndex == RotationType.portrait.rawValue
            videoComposition.renderSize = CGSize(width: mutableComposition.naturalSize.width, height: mutableComposition.naturalSize.height)
        }
        
        playerItem = AVPlayerItem(asset: mutableComposition)
        playerItem.videoComposition = videoComposition
        player.replaceCurrentItem(with: playerItem)
    }
    
    // MARK: - Crop Video
    @IBAction func cropVideoPressed(_ sender: Any) {
        cropVideoByCIFilter()
        //cropVideoByCropRectangle()
    }
    
    func cropVideoByCIFilter() {
        let cropPoint = CGPoint(x: 120, y: 120)
        
        let videoComposition = AVMutableVideoComposition(asset: originAssetVideo, applyingCIFiltersWithHandler: { request in
            
            let source = request.sourceImage
            
            let output = source.transformed(by: CGAffineTransform.init(translationX: -cropPoint.x, y: -cropPoint.y))
            request.finish(with: output, context: nil)
        })
        
        videoComposition.renderSize = CGSize(width: 480 - cropPoint.x, height: 360 - cropPoint.y)
        
        playerItem.videoComposition = videoComposition
        playerItem.audioTimePitchAlgorithm = .varispeed
        player.replaceCurrentItem(with: playerItem)
    }
    
    func cropVideoByCropRectangle() {
        let cropRectangle = CGRect(x: 40, y: 20, width: 50, height: 80)
        
        self.mutableComposition = AVMutableComposition()
        
        originAssetVideo.tracks.forEach { track in
            let trackComposition = self.mutableComposition.addMutableTrack(withMediaType: track.mediaType, preferredTrackID: kCMPersistentTrackID_Invalid)
            try? trackComposition?.insertTimeRange(track.timeRange, of: track, at: .zero)
            trackComposition?.preferredTransform = track.preferredTransform
        }
        
        let tranformer = AVMutableVideoCompositionLayerInstruction.init(assetTrack: mutableComposition.tracks(withMediaType: .video).first!)
        tranformer.setCropRectangle(cropRectangle, at: .zero)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: mutableComposition.duration)
        instruction.layerInstructions = [tranformer]
        
        let videoComposition = AVMutableVideoComposition(propertiesOf: mutableComposition)
        videoComposition.instructions = [instruction]
        videoComposition.renderSize = CGSize(width: cropRectangle.width, height: cropRectangle.height)
        
        playerItem.videoComposition = videoComposition
        playerItem.audioTimePitchAlgorithm = .varispeed
        player.replaceCurrentItem(with: playerItem)
    }
    
    // MARK: - Filter Video
    @IBAction func filterVideoPressed(_ sender: Any) {
        filterVideoIndex = (filterVideoIndex + 1) % 4
        
        if filterVideoIndex == FilterVideoType.ciGaussianBlur.rawValue {
            let filter = CIFilter(name: "CIGaussianBlur")!
            let videoComposion = AVVideoComposition(asset: originAssetVideo, applyingCIFiltersWithHandler: { request in
                
                let source = request.sourceImage.clampedToExtent()
                filter.setValue(source, forKey: kCIInputImageKey)
                
                let seconds = CMTimeGetSeconds(request.compositionTime)
                filter.setValue(seconds * 0.25, forKey: kCIInputRadiusKey)
                
                let output = filter.outputImage!.cropped(to: request.sourceImage.extent)
                request.finish(with: output, context: nil)
            })
            
            playerItem.videoComposition = videoComposion
        }
        else if filterVideoIndex == FilterVideoType.ciBumpDistortion.rawValue {
            let filter = CIFilter(name: "CIBumpDistortion")
            let videoComposition = AVVideoComposition(asset: originAssetVideo, applyingCIFiltersWithHandler: { request in
                
                let source = request.sourceImage.clampedToExtent()
                filter?.setValue(source, forKey: kCIInputImageKey)
                
                let inputCenter = CIVector(values: [150, 150], count: 2)
                filter?.setValue(inputCenter, forKey: "inputCenter")
                
                let inputRadius = NSNumber(value: 200)
                filter?.setValue(inputRadius, forKey: "inputRadius")
                
                let inputScale = NSNumber(value: 0.5)
                filter?.setValue(inputScale, forKey: "inputScale")
                
                let output = filter?.outputImage?.cropped(to: request.sourceImage.extent)
                request.finish(with: output!, context: nil)
            })
            
            playerItem.videoComposition = videoComposition
        }
        else if filterVideoIndex == FilterVideoType.ciColorClamp.rawValue {
            let filter = CIFilter(name: "CIColorClamp")
            
            let videoComposition = AVVideoComposition(asset: originAssetVideo, applyingCIFiltersWithHandler: {request in
                
                let source = request.sourceImage.clampedToExtent()
                filter?.setValue(source, forKey: kCIInputImageKey)
                
                let inputMinComponents = CIVector(x: 0.55, y: 0.15, z: 0.1, w: 1)
                filter?.setValue(inputMinComponents, forKey: "inputMinComponents")
                
                let inputMaxComponents = CIVector(x: 1, y: 1, z: 1, w: 1)
                filter?.setValue(inputMaxComponents, forKey: "inputMaxComponents")
                
                let output = filter?.outputImage?.cropped(to: request.sourceImage.extent)
                request.finish(with: output!, context: nil)
            })
            
            playerItem.videoComposition = videoComposition
        }
        else {
            //let filter = CIFilter(name: "CILinearToSRGBToneCurve") // mau sang
            let filter = CIFilter(name: "CIPhotoEffectMono") // mau den trang
            
            let videoComposition = AVVideoComposition(asset: originAssetVideo, applyingCIFiltersWithHandler: {request in
                
                let source = request.sourceImage.clampedToExtent()
                filter?.setValue(source, forKey: kCIInputImageKey)
                
                let output = filter?.outputImage?.cropped(to: request.sourceImage.extent)
                request.finish(with: output!, context: nil)
            })
            
            playerItem.videoComposition = videoComposition
        }
        
        playerItem.audioTimePitchAlgorithm = .varispeed
        player.replaceCurrentItem(with: playerItem)
    }
    
    // MARK: - Trim Video
    @IBAction func trimVideoPressed(_ sender: Any) {
        saveVideoButton.isHidden = false
        trimButton.isHidden = true
        
        // Add CutAudioView
        cutVideoView = ThumbnailCutVideoView(frame: CGRect(x: 40, y: 10, width: self.view.frame.width - 80, height: 62), fileImage: getThumbnailFrom(path: URL(fileURLWithPath: Bundle.main.path(forResource: "VideoExample1", ofType: "mp4")!))!)
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
        let originVideoTracks = originAssetVideo!.tracks
        
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
        
        playerItem = AVPlayerItem(asset: self.mutableComposition)
        playerItem.audioTimePitchAlgorithm = .varispeed
        self.player.replaceCurrentItem(with: playerItem)
        timeDurationLabel.text = String(playerItem.duration.seconds)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEndTime(_:)), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    @objc func playerItemDidPlayToEndTime(_ notification: Notification) {
        self.player.pause()
        self.player.seek(to: CMTime.zero, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    func getThumbnailFrom(path: URL) -> UIImage? {
        do {
            let asset = AVURLAsset(url: path , options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 2, timescale: 10), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)

            return thumbnail
        }
        catch let error {
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
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
}
