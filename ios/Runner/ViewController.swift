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

/// As of 11/11/2021 the recommended minimum iOS target is 14.0 to make the examples
/// compatible with Headphone Motion Manager API from Apple.
/// if you require targetting an older version of iOS SDK, please remove all logic using
/// `CMHeadphoneMotionManager`or roll back to an older example version.
private var motionManager = CMMotionManager()
@available(iOS 14.0, *)
private var headphoneMotionManager = CMHeadphoneMotionManager()
private var bUseHeadphoneOrientationData = true

var m1obj = Mach1DecodePositional()

var isPlaying = false
var players: [AVAudioPlayer] = [AVAudioPlayer(), AVAudioPlayer()]

var cameraPosition: Mach1Point3D = Mach1Point3D(x: 0, y: 0, z: 0)
var cameraPitch : Float = 0
var cameraYaw : Float = 0
var cameraRoll : Float = 0

var objectPosition: Mach1Point3D = Mach1Point3D(x: 0, y: 0, z: 0)


func mapFloat(value : Float, inMin : Float, inMax : Float, outMin : Float, outMax : Float) -> Float {
    return (value - inMin) / (inMax - inMin) * (outMax - outMin) + outMin
}

func clampFloat(value : Float, min : Float, max : Float) -> Float {
    return min > value ? min : max < value ? max : value
}

func getEuler(q1 : SCNVector4) -> SIMD3<Float>
{
    var res = SIMD3<Float>(0,0,0)
    
    let test = q1.x * q1.y + q1.z * q1.w
    if (test > 0.499) // singularity at north pole
    {
        return SIMD3<Float>(
        0,
        Float(2 * atan2(q1.x, q1.w)),
        .pi / 2
        ) * 180 / .pi
    }
    if (test < -0.499) // singularity at south pole
    {
        return SIMD3<Float>(
        0,
        Float(-2 * atan2(q1.x, q1.w)),
        -.pi / 2
        ) * 180 / .pi
    }
    
    let sqx = q1.x * q1.x
    let sqy = q1.y * q1.y
    let sqz = q1.z * q1.z
    
    res.x = Float(atan2(2 * q1.x * q1.w - 2 * q1.y * q1.z, 1 - 2 * sqx - 2 * sqz))
    res.y = Float(atan2(2 * q1.y * q1.w - 2 * q1.x * q1.z, 1 - 2 * sqy - 2 * sqz))
    res.z = Float(sin(2.0 * test))

    return res * 180 / .pi
}

@available(iOS 14.0, *)
class ViewController: UIViewController, CMHeadphoneMotionManagerDelegate {

    // 音声を再生
    func playAudio(x: Float, y: Float, z: Float) {
        cameraPosition = Mach1Point3D(
            x: x,
            y: y,
            z: z
        )

        print("start: ViewController.playAudio()")
        if !isPlaying {
            let startDelayTime = 1.0
            let now = players[0].deviceCurrentTime
            let startTime = now + startDelayTime
                
            players[0].play(atTime: startTime)
            players[1].play(atTime: startTime)
            isPlaying = true
        }
    }
    
    // 音声を停止
    func stopAudio() {
        print("start: ViewController.stopAudio()")
        players[0].stop()
        players[1].stop()
        isPlaying = false

        players[0].prepareToPlay()
        players[1].prepareToPlay()
    }

    // 回転が取得できているか確認のために使用
    func getCameraRotation() -> Dictionary<String, Float> {
        return ["yaw": cameraYaw, "pitch": cameraPitch, "roll": cameraRoll]
    }

    // 最初に実行される箇所
    func initialize(audioFilePath: String) {
        players = Encoder().setupPlayers(audioFilePath: audioFilePath)
        
        // ===========================
        // Mach1 Decode Setup
        // ===========================
        // Setup the correct angle convention for orientation Euler input angles
        m1obj.setPlatformType(type: Mach1PlatformiOS)
        // Setup the expected spatial audio mix format for decoding
        m1obj.setDecodeAlgoType(newAlgorithmType: Mach1DecodeAlgoSpatial)
        // Setup for the safety filter speed:
        m1obj.setFilterSpeed(filterSpeed: 0.95)

        // ===========================
        // Mach1 Decode Positional Setup
        // ===========================
        // Advanced Setting: used for blending 2 m1obj for crafting room ambiences
        m1obj.setUseBlendMode(useBlendMode: false)
        // Advanced Setting: ignore movements on height plane
        m1obj.setIgnoreTopBottom(ignoreTopBottom: false)
        // Setting: mute audio when setListenerPosition position is outside of m1obj volume
        // based on setDecoderAlgoPosition & setDecoderAlgoScale
        m1obj.setMuteWhenOutsideObject(muteWhenOutsideObject: false)
        // Setting: mute audio when setListenerPosition position is inside of m1obj volume
        // based on setDecoderAlgoPosition & setDecoderAlgoScale
        m1obj.setMuteWhenInsideObject(muteWhenInsideObject: false)
        // Setting: turn on/off distance attenuation of m1obj
        m1obj.setUseAttenuation(useAttenuation: true)
        // Advanced Setting: when on, positional rotation is calculated from the closest point
        // of the m1obj's volume and not rotation from the center of m1obj.
        // use this if you want the positional rotation tracking to be from a plane instead of from a point
        // - 回転の中心は, 面ではなく点で行いたいため, false
        m1obj.setUsePlaneCalculation(bool: false)
        
        //Allow audio to play when app closes
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback)
        } catch {
            print(error)
        }


        /// `headphoneMotionManager` is for headphone IMU enalbed device
        /// `motionManager` is for the native device's IMU
        /// `bUseHeadphones` lazily swaps between both manager's orientation updates
        motionManager = CMMotionManager()
        headphoneMotionManager = CMHeadphoneMotionManager()
        headphoneMotionManager.delegate = self    
        if motionManager.isDeviceMotionAvailable == true {
            // データの更新頻度 (The interval, in seconds, ...)
            // https://developer.apple.com/documentation/coremotion/cmmotionmanager/1616065-devicemotionupdateinterval
            motionManager.deviceMotionUpdateInterval = 0.01
            let queue = OperationQueue()
            /// Start native IMU core motion manager thread
            // TODO: ここの動作確認
            //  サンプルでは以下の実装をしているが,デバイスの更新頻度が高いので
            //  AirPodsでの更新があまり反映されていない気がする？
            motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical,  to: queue, withHandler: { (motion, error) -> Void in
                if (bUseHeadphoneOrientationData && headphoneMotionManager.isDeviceMotionAvailable){
                    headphoneMotionManager.startDeviceMotionUpdates(to: queue, withHandler: { (headphonemotion, error) -> Void in
                        let quat = headphonemotion?.gaze(atOrientation: UIApplication.shared.statusBarOrientation)
                        let angles = getEuler(q1: quat!)
                        cameraYaw = angles.x
                        cameraPitch = angles.y
                        cameraRoll = angles.z
                    })
                    // mach1-positional-exampleでは,以下がないとメモリエラーが発生する
                    if (!headphoneMotionManager.isDeviceMotionActive) {
                        bUseHeadphoneOrientationData = false
                    }
                } else {
                    let quat = motion?.gaze(atOrientation: UIApplication.shared.statusBarOrientation)
                    let angles = getEuler(q1: quat!)
                    cameraYaw = angles.x
                    cameraPitch = angles.y
                    cameraRoll = angles.z
                }

                /// Warning:
                /// You're expected to correct and manage the orientation from devices in accordance with your UX
                /// to get accurate playback from Mach1Decode API
                /// https://dev.mach1.tech/#mach1-internal-angle-standard
                
                /// This example does not have motion management logic in place, it is expected
                /// that the app will be used in Portrait mode held in hand and will assume 0 values for
                /// yaw, pitch, roll upon launch. Rotating the device in portrait mode
                /// is the expected usage.

                //Send device orientation to m1obj with the preferred algo
                m1obj.setListenerPosition(point: (cameraPosition))
                m1obj.setListenerRotation(point: Mach1Point3D(x: cameraYaw, y: cameraPitch, z: cameraRoll))
                m1obj.setDecoderAlgoPosition(point: (objectPosition))
                m1obj.setDecoderAlgoRotation(point: Mach1Point3D(x: 0, y: 0, z: 0))
                m1obj.setDecoderAlgoScale(point: Mach1Point3D(x: 0.1, y: 0.1, z: 0.1))
                m1obj.setUseYawForRotation(bool: true)
                m1obj.setUsePitchForRotation(bool: true)
                m1obj.setUseRollForRotation(bool: true)
                m1obj.evaluatePositionResults()

                // compute attenuation linear curve - project dist [0:1] to [1:0] interval
                var attenuation : Float = m1obj.getDist()
                attenuation = mapFloat(value: attenuation, inMin: 0, inMax: 20, outMin: 1, outMax: 0)
                attenuation = clampFloat(value: attenuation, min: 0, max: 20)
                m1obj.setAttenuationCurve(attenuationCurve: attenuation)

                // Remark: Result is returned back as the argument, an array of 18 floats is required as an input
                var decodeArray: [Float] = Array(repeating: 0.0, count: 18)
                m1obj.getCoefficients(result: &decodeArray)

                //Use each coeff to decode multichannel Mach1 Spatial mix
                players[0].setVolume(Float(decodeArray[0]), fadeDuration: 0)
                players[1].setVolume(Float(decodeArray[1]), fadeDuration: 0)
            })
            print("Device motion started")
        } else {
            print("Device motion unavailable");
        }
    }
}

