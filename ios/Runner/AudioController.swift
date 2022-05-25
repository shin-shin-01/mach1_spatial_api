//
//  ViewController.swift
//  mach1-ios-example
//
//  Created by Dylan Marcus on 2/19/18.
//  Copyright © 2018 Mach1. All rights reserved.
//

import UIKit
import CoreMotion
import AVFoundation
import SceneKit
import Mach1SpatialAPI



@available(iOS 14.0, *)
class AudioController: NSObject, CMHeadphoneMotionManagerDelegate {
    private lazy var motionManager = CMHeadphoneMotionManager()

    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        print("Motion Manager Did Connect")
    }

    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        print("Motion Manager Did Disconnect")
    }

    // HeadphoneMotionを初期化
    func startHeadphoneMotion() {
        motionManager.delegate = self

        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
            if let error = error {
                print("\(error)")
            }

            if let motion = motion {
                self?.updateTargetWithMotion(motion)
            }
        }
    }

    private func updateTargetWithMotion(_ motion: CMDeviceMotion) {
        let attitude = motion.attitude
        // flutter_compass と同様に右方向を正の向きとする
        let yaw = -1 * (attitude.yaw * 180) / .pi
        let pitch = (attitude.pitch * 180) / .pi
        let roll = (attitude.roll * 180) / .pi
        print("========================")
        print("yaw  : \(yaw)")
        print("pitch: \(pitch)")
        print("roll : \(roll)")
        // target.eulerAngles = SCNVector3(attitude.pitch, attitude.yaw, -attitude.roll)
    }
}

