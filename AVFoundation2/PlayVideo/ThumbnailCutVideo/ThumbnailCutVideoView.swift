//
//  ThumbnailCutVideoView.swift
//  AVFoundation2
//
//  Created by Manh Nguyen Ngoc on 27/01/2021.
//

import UIKit

class ThumbnailCutVideoView: UIView {
    public var leftConstraint: NSLayoutConstraint?
    public var rightConstraint: NSLayoutConstraint?
    public var bottomConstraint: NSLayoutConstraint?
    public var topConstraint: NSLayoutConstraint?
    public var fileImage: UIImage!
    public var leftView: UIView!
    public var rightView: UIView!
    public var leftLabel: UILabel!
    public var rightLabel: UILabel!
    public var cutVideo: ThumbnailCutVideo!
    
    public var leftStartTime: Float!
    public var rightEndTime: Float!
    
    init(frame: CGRect, fileImage: UIImage) {
        self.fileImage = fileImage
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        if fileImage != nil {
            let imageView = UIImageView(frame: self.frame)
            imageView.image = fileImage
            imageView.contentMode = .scaleToFill
            imageView.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(imageView)
            
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
            imageView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
            imageView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
            imageView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        }
        
        cutVideo = ThumbnailCutVideo(frame: self.frame)
        cutVideo.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(cutVideo)
        
        leftConstraint = cutVideo.leftAnchor.constraint(equalTo: self.leftAnchor)
        rightConstraint = self.rightAnchor.constraint(equalTo: cutVideo.rightAnchor)
        bottomConstraint = self.bottomAnchor.constraint(equalTo: cutVideo.bottomAnchor)
        topConstraint = cutVideo.topAnchor.constraint(equalTo: self.topAnchor)

        leftConstraint?.isActive = true
        rightConstraint?.isActive = true
        bottomConstraint?.isActive = true
        topConstraint?.isActive = true
        
        configCropLimiUI()
    }
    
    func configCropLimiUI() {
        leftView = UIView(frame: self.frame)
        rightView = UIView(frame: self.frame)
        leftView.backgroundColor = .cyan
        rightView.backgroundColor = .cyan
        leftView.translatesAutoresizingMaskIntoConstraints = false
        rightView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(leftView)
        self.addSubview(rightView)
        
        leftView.leftAnchor.constraint(equalTo: cutVideo.leftAnchor).isActive = true
        leftView.heightAnchor.constraint(equalToConstant: self.frame.height + 20).isActive = true
        leftView.widthAnchor.constraint(equalToConstant: 5).isActive = true
        leftView.centerYAnchor.constraint(equalTo: cutVideo.centerYAnchor).isActive = true
        
        rightView.rightAnchor.constraint(equalTo: cutVideo.rightAnchor).isActive = true
        rightView.heightAnchor.constraint(equalToConstant: self.frame.height + 20).isActive = true
        rightView.widthAnchor.constraint(equalToConstant: 5).isActive = true
        rightView.centerYAnchor.constraint(equalTo: cutVideo.centerYAnchor).isActive = true
        
        let leftPan = UIPanGestureRecognizer(target: self, action: #selector(self.leftPanGesture(_: )))
        leftView.addGestureRecognizer(leftPan)
        let rightPan = UIPanGestureRecognizer(target: self, action: #selector(self.rightPanGesture(_: )))
        rightView.addGestureRecognizer(rightPan)
        
        // MARK: - add new left right label
        leftLabel = UILabel(frame: self.frame)
        rightLabel = UILabel(frame: self.frame)
        
        leftStartTime = Float(leftConstraint!.constant / frame.width)
        leftLabel.text = String(format: "%.0f", leftStartTime * 100) + "%"
        rightEndTime = Float(1 - rightConstraint!.constant / frame.width)
        rightLabel.text = String(format: "%.0f", rightEndTime * 100) + "%"
        leftLabel.textColor = .blue
        rightLabel.textColor = .blue
        leftLabel.translatesAutoresizingMaskIntoConstraints = false
        rightLabel.translatesAutoresizingMaskIntoConstraints = false
        
        leftView.addSubview(leftLabel)
        rightView.addSubview(rightLabel)
        
        leftLabel.topAnchor.constraint(equalTo: leftView.bottomAnchor, constant: 10).isActive = true
        rightLabel.topAnchor.constraint(equalTo: rightView.bottomAnchor, constant: 10).isActive = true
    }
    
    @objc func leftPanGesture(_ sender: Any?) {
        let panGesture = sender as! UIPanGestureRecognizer
        let point = panGesture.location(in: self)
        let distance = point.x
        leftConstraint?.constant = (distance >= 0) ? distance : cutVideo.frame.minX
        leftStartTime = Float(leftConstraint!.constant / frame.width)
        leftLabel.text = String(format: "%.0f", leftStartTime * 100) + "%"
    }
    
    @objc func rightPanGesture(_ sender: Any?) {
        let panGesture = sender as! UIPanGestureRecognizer
        let point = panGesture.location(in: self)
        let distance = self.frame.width - point.x
        rightConstraint?.constant = (distance >= 0) ? distance : 0
        rightEndTime = Float(1 - rightConstraint!.constant / frame.width)
        rightLabel.text = String(format: "%.0f", rightEndTime * 100) + "%"
    }
}


