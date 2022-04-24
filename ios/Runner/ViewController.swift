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
private var bUseHeadphoneOrientationData = true // AirPodsの方位データを使用する

var m1obj = Mach1DecodePositional()

var isPlaying = false
var cameraPitch : Float = 0
var cameraYaw : Float = 0
var cameraRoll : Float = 0

var players: [AVAudioPlayer] = []

var cameraPosition: Mach1Point3D = Mach1Point3D(x: 0, y: 0, z: 0)
var objectPosition: Mach1Point3D = Mach1Point3D(x: 0, y: 0, z: 0)

var cameraPositionOffset: Mach1Point3D = Mach1Point3D(x: 0, y: 0, z: 0)

func mapFloat(value : Float, inMin : Float, inMax : Float, outMin : Float, outMax : Float) -> Float {
    return (value - inMin) / (inMax - inMin) * (outMax - outMin) + outMin
}

func clampFloat(value : Float, min : Float, max : Float) -> Float {
    return min > value ? min : max < value ? max : value
}

func getEuler(q1 : SCNVector4) -> float3
{
    var res = float3(0,0,0)
    
    let test = q1.x * q1.y + q1.z * q1.w
    if (test > 0.499) // singularity at north pole
    {
        return float3(
        0,
        Float(2 * atan2(q1.x, q1.w)),
        .pi / 2
        ) * 180 / .pi
    }
    if (test < -0.499) // singularity at south pole
    {
        return float3(
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

    func playAudio(x: Float, y: Float, z: Float) {
        cameraPosition = Mach1Point3D(
            x: x + cameraPositionOffset.x,
            y: y + cameraPositionOffset.y,
            z: z + cameraPositionOffset.z
        )

        print("start: ViewController.playAudio()")
        if !isPlaying {
            let startDelayTime = 1.0
            let now = players[0].deviceCurrentTime
            let startTime = now + startDelayTime
            for audioPlayer in players {
                audioPlayer.play(atTime: startTime)
            }
            print("isPlaying")
            isPlaying = true
        }
    }
    
    func stopAudio() {
        print("start: ViewController.stopAudio()")
        for audioPlayer in players {
            audioPlayer.stop()
        }
        
        isPlaying = false
        // prep files for next play
        for i in stride(from: 0, to: players.count, by: 2) {
            players[i + 0].prepareToPlay()
            players[i + 1].prepareToPlay()
        }
    }

    // 最初に実行される箇所
    func initialize() {
        do {
            Encoder().setup()
            players = Encoder().setupPlayers()
            
            // ===========================
            // Mach1 Decode Setup
            // ===========================
            // Setup the correct angle convention for orientation Euler input angles
            // オイラー入力角度に正しい角度規則を設定する。
            m1obj.setPlatformType(type: Mach1PlatformiOS)
            // Setup the expected spatial audio mix format for decoding
            // デコード時に想定される空間音声のミックス形式を設定する。
            m1obj.setDecodeAlgoType(newAlgorithmType: Mach1DecodeAlgoSpatial)
            // Setup for the safety filter speed:
            // セーフティーフィルターの回転数の設定
            //1.0 = no filter | 0.1 = slow filter
            m1obj.setFilterSpeed(filterSpeed: 0.95)

            // ===========================
            // Mach1 Decode Positional Setup
            // ===========================
            // Advanced Setting: used for blending 2 m1obj for crafting room ambiences
            // 高度な設定：2つのm1objをブレンドしてルームアンビエンスを作成する際に使用します。
            m1obj.setUseBlendMode(useBlendMode: false)
            // Advanced Setting: ignore movements on height plane
            // 高度な設定：高さ方向の動きを無視します。-> false
            m1obj.setIgnoreTopBottom(ignoreTopBottom: false)
            // Setting: mute audio when setListenerPosition position is outside of m1obj volume
            // based on setDecoderAlgoPosition & setDecoderAlgoScale
            // 設定：setListenerPositionの位置がm1objのボリュームの外にある場合、音声をミュートする。
            // setDecoderAlgoPosition と setDecoderAlgoScale に基づいています
            m1obj.setMuteWhenOutsideObject(muteWhenOutsideObject: false)
            // Setting: mute audio when setListenerPosition position is inside of m1obj volume
            // based on setDecoderAlgoPosition & setDecoderAlgoScale
            // 設定：setListenerPositionの位置がm1objのボリュームの内側にあるとき、音声をミュートする。
            // setDecoderAlgoPosition と setDecoderAlgoScale に基づいています。
            m1obj.setMuteWhenInsideObject(muteWhenInsideObject: true)
            // Setting: turn on/off distance attenuation of m1obj
            // 設定：m1objの距離減衰のON/OFF。
            m1obj.setUseAttenuation(useAttenuation: true)
            // Advanced Setting: when on, positional rotation is calculated from the closest point
            // of the m1obj's volume and not rotation from the center of m1obj.
            // use this if you want the positional rotation tracking to be from a plane instead of from a point
            // 詳細設定：オンにすると、位置の回転は、m1objの中心からの回転ではなく、
            // m1objのボリュームの最も近い点から計算されます。
            m1obj.setUsePlaneCalculation(bool: false)
        } catch {
            print (error)
        }
        
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
            /// ヘッドホンから情報が取得できるならそれを利用し, そうでない場合にデバイスの情報を取得する
            motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: queue, withHandler: { [weak self] (motion, error) -> Void in
                if (bUseHeadphoneOrientationData && headphoneMotionManager.isDeviceMotionAvailable){
                    headphoneMotionManager.startDeviceMotionUpdates(to: queue, withHandler: { [weak self] (headphonemotion, error) -> Void in
                        // Get the attitudes of the device
                        let quat = headphonemotion?.gaze(atOrientation: UIApplication.shared.statusBarOrientation)

                        let angles = getEuler(q1: quat!)
                        cameraYaw = angles.x
                        cameraPitch = angles.y
                        cameraRoll = angles.z

                        // TODO: ここがちゃんと反映されているか確認する
                        print("======================")
                        print(cameraYaw)
                        print(cameraPitch)
                        print(cameraRoll)

                    })
                    if (!headphoneMotionManager.isDeviceMotionActive) {
                        bUseHeadphoneOrientationData = false // AirPodsからデータが更新されていなかったら, false
                    }
                } else {
                    // Get the attitudes of the device
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
                m1obj.setListenerPosition(point: (cameraPosition)) // 自身の位置
                m1obj.setListenerRotation(point: Mach1Point3D(x: cameraYaw, y: cameraPitch, z: cameraRoll)) // 回転角: AirPods or iPhone
                m1obj.setDecoderAlgoPosition(point: (objectPosition)) // 対象物の位置
                m1obj.setDecoderAlgoRotation(point: Mach1Point3D(x: 0, y: 0, z: 0)) // 対象物の角度
                m1obj.setDecoderAlgoScale(point: Mach1Point3D(x: 0.1, y: 0.1, z: 0.1)) // 対象物の大きさ？
                
                //ロール・ピッチ・ヨー: x軸-・y軸・z軸の順で回転
                m1obj.setUseYawForRotation(bool: true)
                m1obj.setUsePitchForRotation(bool: true)
                m1obj.setUseRollForRotation(bool: true)

                m1obj.evaluatePositionResults()

                // compute attenuation linear curve - project dist [0:1] to [1:0] interval
                var attenuation : Float = m1obj.getDist()
                attenuation = mapFloat(value: attenuation, inMin: 0, inMax: 100, outMin: 1, outMax: 0)
                attenuation = clampFloat(value: attenuation, min: 0, max: 100) // 100メートル？
                m1obj.setAttenuationCurve(attenuationCurve: attenuation)

                var decodeArray: [Float] = Array(repeating: 0.0, count: 18)
                m1obj.getCoefficients(result: &decodeArray)

                //Use each coeff to decode multichannel Mach1 Spatial mix
                for i in stride(from: 0, to: players.count, by: 2) {
                    players[i * 2].setVolume(Float(decodeArray[i * 2]), fadeDuration: 0)
                    players[i * 2 + 1].setVolume(Float(decodeArray[i * 2 + 1]), fadeDuration: 0)
                }
            })
            print("Device motion started")
        } else {
            print("Device motion unavailable");
        }
    }
}

