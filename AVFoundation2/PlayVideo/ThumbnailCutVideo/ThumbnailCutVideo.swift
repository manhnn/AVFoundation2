//
//  ThumbnailCutVideo.swift
//  AVFoundation2
//
//  Created by Manh Nguyen Ngoc on 27/01/2021.
//

import UIKit

class ThumbnailCutVideo: UIView {

    var topStartPoint: CGPoint?
    var bottomStartPoint: CGPoint?
    var distance = CGPoint(x: 8, y: 0)

    override init(frame: CGRect) {
        topStartPoint = CGPoint(x: -frame.height, y: 0)
        bottomStartPoint = CGPoint(x: 0, y: frame.height)
        super.init(frame: frame)
        self.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        let bezier = UIBezierPath()
        var topPoint = topStartPoint
        var bottomPoint = bottomStartPoint

        while topPoint!.x <= rect.width {
            bezier.move(to: topPoint!)
            bezier.addLine(to: bottomPoint!)

            topPoint!.x += distance.x
            topPoint!.y += distance.y
            bottomPoint!.x += distance.x
            bottomPoint!.y += distance.y
        }
        bezier.stroke()
    }
}
