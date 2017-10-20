//
//  DBSphereView.swift
//  sphereTagCloud
//
//  Created by Xinbao Dong on 14/8/31.
//  Copyright (c) 2014年 Xinbao Dong. All rights reserved.
//

import UIKit

struct DBPoint {
    let x: CGFloat
    let y: CGFloat
    let z: CGFloat
}

open class DBSphereView: UIView, UIGestureRecognizerDelegate {
    
    var tags: [UIView]
    var coordinate = [DBPoint]()
    var normalDirection: DBPoint
    var last = CGPoint.zero
    
    var velocity: CGFloat = 0.0
    
    var timer: CADisplayLink!
    var inertia: CADisplayLink!
    
    // MARK: - initial set
    
    /**
     *  Sets the cloud's tag views.
     *
     *	@remarks Any @c UIView subview can be passed in the array.
     *
     *  @param array The array of tag views.
     */
    public func setCloudTags(_ array: [UIView]) {
        tags = array
//        coordinate = [Any]() /* capacity: 0 */
        for i in 0..<tags.count {
            let view:UIView = tags[i]
            view.center = CGPoint(x: self.frame.size.width / 2.0, y: self.frame.size.height / 2.0)
        }
        let p1: CGFloat = .pi * (3 - sqrt(5))
        let p2: CGFloat = 2.0 / CGFloat(tags.count)
        for i in 0..<tags.count {
            let y: CGFloat = CGFloat(i) * p2 - 1 + (p2 / 2)
            let r: CGFloat = sqrt(1 - y * y)
            let p3: CGFloat = CGFloat(i) * p1
            let x: CGFloat = cos(p3) * r
            let z: CGFloat = sin(p3) * r
            
            let point = DBPoint(x: x, y: y, z: z)
//            let value: NSValue = NSValue(cgRect: CGRect(x:0, y:0, width:1, height:1));
//            value.getValue(&point)
            coordinate.append(point)
            
            let time: CGFloat = (CGFloat(arc4random() % 10) + 10.0) / 20.0
            UIView.animate(withDuration: TimeInterval(time), delay: 0.0, options: .curveEaseOut, animations: {() -> Void in
                self.setTagOf(point, andIndex: i)
            }, completion: {(_ finished: Bool) -> Void in
            })
        }
        
        let a:NSInteger = NSInteger(arc4random() % 10) - 5
        let b:NSInteger = NSInteger(arc4random() % 10) - 5
        normalDirection = DBPoint(x: CGFloat(a), y: CGFloat(b), z: 0)
        self.timerStart()
    }
    
    /**
     *  Starts the cloud autorotation animation.
     */
    func timerStart() {
        timer = CADisplayLink(target: self, selector: #selector(self.autoTurnRotation))
        timer.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    /**
     *  Stops the cloud autorotation animation.
     */
    func timerStop() {
//        timer.invalidate()
        timer = nil
    }

    override public init(frame: CGRect) {
        self.tags = []
        self.coordinate = []
        self.normalDirection = DBPoint(x: 0, y: 0, z: 0)
        super.init(frame: frame)
        
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture))
        self.addGestureRecognizer(gesture)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - set frame of point
    
    func updateFrameOfPoint(_ index: Int, direction: DBPoint, andAngle angle: CGFloat) {
//        var value: NSValue = coordinate[index] as! NSValue
//        var point: DBPoint = DBPoint(x: 0, y: 0, z: 0)
//        value.getValue(&point)
        let point: DBPoint = coordinate[index] as! DBPoint
        
        let rPoint = DBPointMakeRotation(point: point, direction: direction, angle: angle)
        coordinate[index] = rPoint
        
        self.setTagOf(rPoint, andIndex: index)
    }
    
    func setTagOf(_ point: DBPoint, andIndex index: Int) {
        let view: UIView = tags[index] as! UIView
        view.center = CGPoint(x: (point.x + 1) * (self.frame.size.width / 2.0), y: (point.y + 1) * self.frame.size.width / 2.0)
        
        let transform: CGFloat = (point.z + 2) / 3
        view.transform = CGAffineTransform.identity.scaledBy(x: transform, y: transform)
        view.layer.zPosition = transform
        view.alpha = transform
        if point.z < 0 {
            view.isUserInteractionEnabled = false
        }
        else {
            view.isUserInteractionEnabled = true
        }
    }
    
    // MARK: - autoTurnRotation
    
    @objc func autoTurnRotation() {
        for i in 0..<tags.count {
            self.updateFrameOfPoint(i, direction: normalDirection, andAngle: 0.002)
        }
    }
    
    // MARK: - inertia
    
    func inertiaStart() {
        self.timerStop()
        inertia = CADisplayLink(target: self, selector: #selector(self.inertiaStep))
        inertia.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    func inertiaStop() {
//        inertia.invalidate()
        inertia = nil
        self.timerStart()
    }
    
    @objc func inertiaStep() {
        if velocity <= 0 {
            self.inertiaStop()
        }
        else {
            velocity -= 70.0
            let angle: CGFloat = velocity / self.frame.size.width * 2.0 * CGFloat(inertia.duration)
            for i in 0..<tags.count {
                self.updateFrameOfPoint(i, direction: normalDirection, andAngle: angle)
            }
        }
    }
    
    // MARK: - gesture selector
    
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == .began {
            last = gesture.location(in: self)
            self.timerStop()
            self.inertiaStop()
        }
        else if gesture.state == .changed {
            let current = gesture.location(in: self)
            let direction = DBPoint(x: last.y - current.y, y: current.x - last.x, z: 0)
            let distance: CGFloat = sqrt(direction.x * direction.x + direction.y * direction.y)
            let angle: CGFloat = distance / (self.frame.size.width / 2.0)
            for i in 0..<tags.count {
                self.updateFrameOfPoint(i, direction: direction, andAngle: angle)
            }
            normalDirection = direction
            last = current
        }
        else if gesture.state == .ended {
            let velocityP = gesture.velocity(in: self)
            velocity = sqrt(velocityP.x * velocityP.x + velocityP.y * velocityP.y)
            self.inertiaStart()
        }
        
    }
}