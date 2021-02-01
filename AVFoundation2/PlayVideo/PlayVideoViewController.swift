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
    var playerItem: AVPlayerItem!
    var originVideo: AVAsset?
    var originVideo2: AVAsset?
    var originAudio: AVAsset?
    var videoComposition: AVVideoComposition!
    
    let musicString = Bundle.main.path(forResource: "SampleAudio1", ofType: "mp3")!
    let videoString = Bundle.main.path(forResource: "SampleVideo1", ofType: "mp4")!
    let videoString2 = Bundle.main.path(forResource: "SampleVideo2", ofType: "mp4")!
    var urlVideo: URL?
    var urlVideo2: URL?
    var urlAudio: URL?
    var isVideoPlaying = false
    var isZoomVideo = false
    var listRate: [Float] = [1, 1.25, 1.5, 1.75, 2, 0.25, 0.5, 0.75]
    var rateNumber: Int = 0
    var isLoop = false
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        urlAudio = URL(fileURLWithPath: musicString)
        urlVideo = URL(fileURLWithPath: videoString)
        urlVideo2 = URL(fileURLWithPath: videoString2)
        player = AVPlayer(url: urlVideo!)
        originVideo = AVAsset(url: urlVideo!)
        originVideo2 = AVAsset(url: urlVideo2!)
        originAudio = AVAsset(url: urlAudio!)
        player.currentItem?.addObserver(self, forKeyPath: "duration", options: [.new, .initial], context: nil)
        playerItem = player.currentItem
        mutableComposition = AVMutableComposition()
        addTimeObserver()
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
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
    
    func showAlert(title: String, message: String) {
        let alertView = UIAlertController(title:title, message:message, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: NSLocalizedString("OK",comment:"OK"), style: .default, handler: nil)
        alertView.addAction(defaultAction)
        self.present(alertView, animated: true, completion: nil)
    }
    
    
    // MARK: - Button Controller Video
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
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 2, timescale: 10), actualTime: nil)
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
        
        let originAudio = AVAsset(url: urlAudio!)
        let originVideoTracks = originAudio.tracks
        
        //originVideo = AVAsset(url: urlVideo!)
        
        originVideoTracks.forEach { (track) in
            if track.mediaType == .audio {
                let trackComposition = self.mutableComposition.addMutableTrack(withMediaType: track.mediaType, preferredTrackID: track.trackID)
                try? trackComposition?.insertTimeRange(CMTimeRange(start: CMTime(seconds: 0, preferredTimescale: 1), duration: CMTime(seconds: 60, preferredTimescale: 1)), of: track, at: .zero)
                trackComposition?.scaleTimeRange(CMTimeRange(start: CMTime(seconds: 0, preferredTimescale: 1), duration: CMTime(seconds: 60, preferredTimescale: 1)), toDuration: CMTime(seconds: 25, preferredTimescale: 1))
            }
        }
        let trackCompositionz = self.mutableComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        try? trackCompositionz?.insertTimeRange(CMTimeRange(start: CMTime(seconds: 0, preferredTimescale: 1), duration: originAudio.duration), of: originVideo!.tracks(withMediaType: .video).first!, at: .zero)
        
        playerItem = AVPlayerItem(asset: self.mutableComposition)
        playerItem.audioTimePitchAlgorithm = .varispeed
        player.replaceCurrentItem(with: playerItem)
    }
    
    // MARK: - Filter Video
    @IBAction func filterVideo(_ sender: UIButton) {
        
        let filter = CIFilter(name: "CIGaussianBlur")!
        let originAsset = AVAsset(url: urlVideo!)

        let videoComposition = AVVideoComposition(asset: originAsset, applyingCIFiltersWithHandler: { request in

            // Clamp to avoid blurring transparent pixels at the image edges
            let source = request.sourceImage.clampedToExtent()
            filter.setValue(source, forKey: kCIInputImageKey)

            // Vary filter parameters based on video timing
            let seconds = CMTimeGetSeconds(request.compositionTime)
            filter.setValue(seconds * 0.25, forKey: kCIInputRadiusKey)

            // Crop the blurred output to the bounds of the original image
            let output = filter.outputImage!.cropped(to: request.sourceImage.extent)

            // Provide the filter output to the composition
            request.finish(with: output, context: nil)
        })
      
        //let playerItem = AVPlayerItem(asset: self.mutableComposition) chi can thay doi thuoc tinh videoComsition chu ko can khoi tao item moi
        playerItem.videoComposition = videoComposition
        playerItem.audioTimePitchAlgorithm = .varispeed
        player.replaceCurrentItem(with: playerItem)
    }
    
    @IBAction func filterVideo2(_ sender: Any) {
        let filter = CIFilter(name: "CIBumpDistortion")
        let originAsset = AVAsset(url: urlVideo!)
        
        let videoComposition = AVVideoComposition(asset: originAsset, applyingCIFiltersWithHandler: { request in
            
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
        
        //let playerItem = AVPlayerItem(asset: self.mutableComposition) chi can thay doi thuoc tinh videoComposition chu ko can khoi tao lai item moi
        playerItem.videoComposition = videoComposition
        playerItem.audioTimePitchAlgorithm = .varispeed
        player.replaceCurrentItem(with: playerItem)
    }
    
    @IBAction func filterVideo3(_ sender: Any) {
        let filter = CIFilter(name: "CIColorClamp")
        let originAsset = AVAsset(url: urlVideo!)
        
        let videoComposition = AVVideoComposition(asset: originAsset, applyingCIFiltersWithHandler: {request in
            
            let source = request.sourceImage.clampedToExtent()
            filter?.setValue(source, forKey: kCIInputImageKey)
            
            let inputMinComponents = CIVector(x: 0.55, y: 0.15, z: 0.1, w: 1)
            filter?.setValue(inputMinComponents, forKey: "inputMinComponents")
            
            let inputMaxComponents = CIVector(x: 1, y: 1, z: 1, w: 1)
            filter?.setValue(inputMaxComponents, forKey: "inputMaxComponents")
            
            let output = filter?.outputImage?.cropped(to: request.sourceImage.extent)
            request.finish(with: output!, context: nil)
        })
        
        //let playerItem = AVPlayerItem(asset: self.mutableComposition) chi can thay doi thuoc tinh videoCompositon chu ko can khoi tao lai item moi
        playerItem.videoComposition = videoComposition
        playerItem.audioTimePitchAlgorithm = .varispeed
        player.replaceCurrentItem(with: playerItem)
    }
    
    @IBAction func filterVideo4(_ sender: Any) {
        //let filter = CIFilter(name: "CILinearToSRGBToneCurve") // mau sang
        let filter = CIFilter(name: "CIPhotoEffectMono") // mau den trang
        let originAsset = AVAsset(url: urlVideo!)
        
        let videoComposition = AVVideoComposition(asset: originAsset, applyingCIFiltersWithHandler: {request in
            
            let source = request.sourceImage.clampedToExtent()
            filter?.setValue(source, forKey: kCIInputImageKey)
            
            let output = filter?.outputImage?.cropped(to: request.sourceImage.extent)
            request.finish(with: output!, context: nil)
        })
        
        //let playerItem = AVPlayerItem(asset: self.mutableComposition) chi can thay doi thuoc tinh videoComposition chu ko can khoi tao lai item moi
        playerItem.videoComposition = videoComposition
        playerItem.audioTimePitchAlgorithm = .varispeed
        player.replaceCurrentItem(with: playerItem)
    }
    
    // MARK: - Trim video
    @IBAction func trimVideoButton(_ sender: Any) {
        
        saveVideoButton.isHidden = false
        trimButton.isHidden = true
        
        // Add CutAudioView
        cutVideoView = ThumbnailCutVideoView(frame: CGRect(x: 40, y: 10, width: self.view.frame.width - 80, height: 62), fileImage: getThumbnailFrom(path: urlVideo!)!)
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
        originVideo = AVAsset(url: urlVideo! as URL)
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
        
        playerItem = AVPlayerItem(asset: self.mutableComposition)
        playerItem.audioTimePitchAlgorithm = .varispeed
        self.player.replaceCurrentItem(with: playerItem)
        durationTimeLabel.text = getTimeString(from: playerItem.duration)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEndTime(_:)), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    @objc func playerItemDidPlayToEndTime(_ notification: Notification) {
        self.player.pause()
        self.player.seek(to: CMTime.zero, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    // MARK: - Rotate Video
    @IBAction func rotateVideo(_ sender: Any) {
        
        self.mutableComposition = AVMutableComposition()
        
        originVideo!.tracks.forEach { track in
            let trackComposition = self.mutableComposition.addMutableTrack(withMediaType: track.mediaType, preferredTrackID: kCMPersistentTrackID_Invalid)
            try? trackComposition?.insertTimeRange(track.timeRange, of: track, at: .zero)
            trackComposition?.preferredTransform = track.preferredTransform
        }
        
        let videoComposition = AVMutableVideoComposition()
        
        // fix input alpha rotation from UI
        let alpha: CGFloat = .pi
        
        let transformer = AVMutableVideoCompositionLayerInstruction.init(assetTrack: mutableComposition.tracks(withMediaType: .video).first!)
        let transform1: CGAffineTransform
        let transform2: CGAffineTransform
        
        let scale = mutableComposition.naturalSize.height / mutableComposition.naturalSize.width
        
        // rotation alpha = PI
        if alpha == .pi {
            transform1 = CGAffineTransform(translationX: mutableComposition.naturalSize.width, y: mutableComposition.naturalSize.height)
            transform2 = transform1.rotated(by: alpha).scaledBy(x: 1, y: 1)
            transformer.setTransform(transform2, at: .zero)
        }
        // rotation alpha = PI / 2
        else if alpha == .pi * (1 / 2) {
            transform1 = CGAffineTransform(translationX: mutableComposition.naturalSize.width * scale, y: 0)
            transform2 = transform1.rotated(by: alpha).scaledBy(x: scale, y: scale)
            transformer.setTransform(transform2, at: .zero)
        }
        // rotation alpha = 3 PI / 2
        else {
            transform1 = CGAffineTransform(translationX: mutableComposition.naturalSize.height / 2 * scale, y: mutableComposition.naturalSize.width * scale)
            transform2 = transform1.rotated(by: alpha).scaledBy(x: scale, y: scale)
            transformer.setTransform(transform2, at: .zero)
        }
        
        let layerInstruction = AVMutableVideoCompositionInstruction.init()
        layerInstruction.timeRange = CMTimeRangeMake(start: .zero, duration: mutableComposition.duration)
        
        layerInstruction.layerInstructions = [transformer]
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.instructions = [layerInstruction]
        videoComposition.renderSize = mutableComposition.naturalSize
        
        self.videoComposition = videoComposition
        playerItem = AVPlayerItem(asset: mutableComposition)
        playerItem.videoComposition = videoComposition
        player.replaceCurrentItem(with: playerItem)
        
        // Note Rtation
        //    -add các track vào mutalbleComposition(như cắt vs add nhạc)
        //    -rồi dùng layerInstruction có hàm setTransform để di chuyển, translate hay rotation(đang để là .pi/2).
        //    -Config Layer Instruction
        //    -gan lai videoComposition(sai o day)
        //    -rồi replace lại item
    }
    
    // MARK: - Crop Video
    @IBAction func cropVideo(_ sender: Any) {
        //cropvideoTranslatedThenUpdateRenderSize()
        cropVideoCropRectangle()
        //cropVideoByFilterCICrop()
    }
    
    func cropvideoTranslatedThenUpdateRenderSize() {
        //var layerInstruction = AVMutableVideoCompositionLayerInstruction()
        
        self.mutableComposition = AVMutableComposition()
        
        originVideo!.tracks.forEach { track in
            let trackComposition = self.mutableComposition.addMutableTrack(withMediaType: track.mediaType, preferredTrackID: kCMPersistentTrackID_Invalid)
            try? trackComposition?.insertTimeRange(track.timeRange, of: track, at: .zero)
            trackComposition?.preferredTransform = track.preferredTransform
            
            //layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
            //layerInstruction.setCropRectangle(CGRect(x: 10, y: 10, width: 50, height: 50), at: .zero)
            
        }
        let transformer = AVMutableVideoCompositionLayerInstruction.init(assetTrack: mutableComposition.tracks(withMediaType: .video).first!)
        let transform1 = CGAffineTransform(translationX: -100, y: -100)
        transformer.setTransform(transform1, at: .zero)
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: CMTimeMakeWithSeconds(.zero, preferredTimescale: Int32(mutableComposition.duration.seconds)) )
        
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        instruction.layerInstructions = [transformer]
        //instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]
        
        videoComposition.renderSize = CGSize(width: mutableComposition.naturalSize.width, height: mutableComposition.naturalSize.height)
        
        playerItem = AVPlayerItem(asset: mutableComposition)
        playerItem.videoComposition = videoComposition
        player.replaceCurrentItem(with: playerItem)
    }
    
    func cropVideoCropRectangle() {
        self.mutableComposition = AVMutableComposition()
        
        originVideo!.tracks.forEach { track in
            let trackComposition = self.mutableComposition.addMutableTrack(withMediaType: track.mediaType, preferredTrackID: kCMPersistentTrackID_Invalid)
            try? trackComposition?.insertTimeRange(track.timeRange, of: track, at: .zero)
            trackComposition?.preferredTransform = track.preferredTransform
        }
        let videoComposition = AVMutableVideoComposition(propertiesOf: mutableComposition)
                
        let transformer = AVMutableVideoCompositionLayerInstruction.init(assetTrack: mutableComposition.tracks(withMediaType: .video).first!)
         transformer.setCropRectangle(CGRect(x: 100, y: 100, width: 100, height: 100), at: .zero)
        //transformer.setCropRectangleRamp(fromStartCropRectangle: CGRect(x: 100, y: 100, width: 100, height: 100), toEndCropRectangle: CGRect(x: 200, y: 200, width: 200, height: 200), timeRange: CMTimeRange(start: .zero, duration: CMTime(seconds: 10, preferredTimescale: 600)))
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: mutableComposition.duration)
        instruction.layerInstructions = [transformer]
        
        //videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.instructions = [instruction]
        videoComposition.renderSize = CGSize(width: mutableComposition.naturalSize.width, height: mutableComposition.naturalSize.height)
        
        playerItem.videoComposition = videoComposition
        player.replaceCurrentItem(with: playerItem)
    }
    
    func cropVideoByFilterCICrop() {
        let filter = CIFilter(name: "CICrop")
        let originAsset = AVAsset(url: urlVideo!)
        
        let videoComposition = AVMutableVideoComposition(asset: originAsset, applyingCIFiltersWithHandler: { request in
            
            let source = request.sourceImage.clampedToExtent()
            filter?.setValue(source, forKey: kCIInputImageKey)
            
            let inputRectangle = CIVector(cgRect: CGRect(x: 10, y: 10, width: 200, height: 100))
            filter?.setValue(inputRectangle, forKey: "inputRectangle")
            
            let output = filter?.outputImage?.cropped(to: request.sourceImage.extent)
            request.finish(with: output!, context: nil)
        })
        
        videoComposition.renderSize = CGSize(width: 200, height: 100)
        playerItem.videoComposition = videoComposition
        playerItem.audioTimePitchAlgorithm = .varispeed
        player.replaceCurrentItem(with: playerItem)
        //playerLayer.videoGravity = .resize
    }
    
    // MARK: - Merge Video
    @IBAction func mergerVideo(_ sender: Any) {
        self.mutableComposition = AVMutableComposition()
        
        guard let firstTrack = mutableComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { return }
        do { try firstTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: originVideo!.duration), of: originVideo!.tracks(withMediaType: .video)[0], at: .zero)
        } catch {
            print("Failed to load first track")
            return
        }
        
        guard let secondtrack = mutableComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { return }
        do { try secondtrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: originVideo2!.duration), of: originVideo2!.tracks(withMediaType: .video)[0], at: originVideo!.duration)
        }
        catch {
            print("Failed to load second track")
            return
        }
        
        if let loadedAudioAsset1 = originVideo {
            let audioTrack = mutableComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: 0)
            do {
                try audioTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: originVideo!.duration), of: loadedAudioAsset1.tracks(withMediaType: .audio)[0], at: .zero)
            }
            catch {
                print("Failed to load Audio track")
            }
        }
        
        if let loadedAudioAsset2 = originVideo2 {
            let audioTrack = mutableComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: 0)
            do {
                try audioTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: originVideo2!.duration), of: loadedAudioAsset2.tracks(withMediaType: .audio)[0], at: originVideo!.duration)
            }
            catch {
                print("Failed to load Audio track")
            }
        }
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(start: .zero, duration: CMTimeAdd(originVideo!.duration, originVideo2!.duration))
        
        let firstInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: mutableComposition.tracks[0])
        firstInstruction.setOpacity(0.0, at: originVideo!.duration)
        let transform1 = firstTrack.preferredTransform.concatenating(CGAffineTransform.init(translationX: 1, y: 0))
        firstInstruction.setTransform(transform1, at: .zero)
        
        let secondInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: mutableComposition.tracks[1])
        let transform2 = CGAffineTransform(translationX: 1, y: 0).scaledBy(x: 1 / 6, y: 2 / 9)
        secondInstruction.setTransform(transform2, at: originVideo!.duration)
        
        mainInstruction.layerInstructions = [firstInstruction, secondInstruction]
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [mainInstruction]
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        videoComposition.renderSize = CGSize(width: firstTrack.naturalSize.width, height: firstTrack.naturalSize.height)

        
        self.showAlert(title: NSLocalizedString("Done!", comment: "Done!"), message: NSLocalizedString("Videos have been merged", comment: "Video merge success message"))
        
        durationTimeLabel.text = self.getTimeString(from: mutableComposition.duration)
        playerItem = AVPlayerItem(asset: mutableComposition)
        playerItem.videoComposition = videoComposition
        player.replaceCurrentItem(with: playerItem)
    }
}

