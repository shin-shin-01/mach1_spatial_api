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
import Mach1SpatialAPI
import UIKit

/// As of 11/11/2021 the recommended minimum iOS target is 14.0 to make the examples
/// compatible with Headphone Motion Manager API from Apple.
/// if you require targetting an older version of iOS SDK, please remove all logic using
/// `CMHeadphoneMotionManager`or roll back to an older example version.
private var motionManager = CMMotionManager()
@available(iOS 14.0, *)
private var headphoneMotionManager = CMHeadphoneMotionManager()
private var bUseCoreMotionHeadphones = false

var m1obj = Mach1DecodePositional()
var stereoPlayer = AVAudioPlayer()

var stereoActive = false
var isYawActive = true
var isPitchActive = true
var isRollActive = true
var isPlaying = false
var cameraPitch : Float = 0
var cameraYaw : Float = 0
var cameraRoll : Float = 0

// // -3 ~ 3
// var sliderCameraX : Float = 0
// var sliderCameraY : Float = 0
// var sliderCameraZ : Float = -0.5

private var audioEngine: AVAudioEngine = AVAudioEngine()
private var mixer: AVAudioMixerNode = AVAudioMixerNode()
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
    
    @IBOutlet weak var UseHeadphoneOrientationDataSwitch: UISwitch!
    @IBOutlet weak var yaw: UILabel!
    @IBOutlet weak var pitch: UILabel!
    @IBOutlet weak var roll: UILabel!

    func playButton() {
        print("start: ViewController.playButton()")
        if !isPlaying {
            var startDelayTime = 1.0
            var now = players[0].deviceCurrentTime
            var startTime = now + startDelayTime
            print (startTime)
            for audioPlayer in players {
                audioPlayer.play(atTime: startTime)
            }
            //stereoPlayer.play()
            print("isPlaying")
            isPlaying = true
        }
    }
    
    func stopButton() {
        print("start: ViewController.stopButton()")
        for audioPlayer in players {
            audioPlayer.stop()
        }
        isPlaying = false
        //stereoPlayer.stop()
        // prep files for next play
        for i in 0...7 {
            players[i * 2].prepareToPlay()
            players[i * 2 + 1].prepareToPlay()
        }
        //stereoPlayer.prepareToPlay()
    }

    // // CommentOut
    // @IBAction func staticStereoActive(_ sender: Any) {
    //     stereoActive = !stereoActive
    // }
    // @IBAction func headphoneIMUActive(_ sender: Any) {
    //     bUseCoreMotionHeadphones = UseHeadphoneOrientationDataSwitch.isOn
    // }
    // @IBAction func yawActive(_ sender: Any) {
    //     isYawActive = !isYawActive
    // }
    // @IBAction func pitchActive(_ sender: Any) {
    //     isPitchActive = !isPitchActive
    // }
    // @IBAction func rollActive(_ sender: Any) {
    //     isRollActive = !isRollActive
    // }
    // func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
    //     print("connect")
    //     bUseCoreMotionHeadphones = true
    //     DispatchQueue.main.async() {
    //         self.UseHeadphoneOrientationDataSwitch.setOn(bUseCoreMotionHeadphones, animated: true)
    //     }
    // }
    // func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
    //     print("disconnect")
    //     bUseCoreMotionHeadphones = false
    //     DispatchQueue.main.async() {
    //         self.UseHeadphoneOrientationDataSwitch.setOn(bUseCoreMotionHeadphones, animated: true)
    //     }
    // }


    // 最初に実行される箇所
    func initialize() {
        do {
            for i in 0...7 {
                //load in the individual streams of audio from a Mach1 Spatial encoded audio file
                //this example assumes you have decoded the multichannel (8channel) audio file into individual streams
                // Mach1 Spatialでエンコードされたオーディオファイルから、個々のストリームを読み込む。
                // この例では、マルチチャンネル（8チャンネル）のオーディオファイルを個々のストリームにデコードした場合を想定しています。
                players.append(try AVAudioPlayer(contentsOf: URL.init(fileURLWithPath: Bundle.main.path(forResource: "00" + String(i), ofType: "aif")!)))
                players.append(try AVAudioPlayer(contentsOf: URL.init(fileURLWithPath: Bundle.main.path(forResource: "00" + String(i), ofType: "aif")!)))
                
                players[i * 2].numberOfLoops = 10
                players[i * 2 + 1].numberOfLoops = 10
                
                //the Mach1Decode function 8*2 channels to correctly recreate the stereo image
                players[i * 2].pan = -1.0;
                players[i * 2 + 1].pan = 1.0;
                
                players[i * 2].prepareToPlay()
                players[i * 2 + 1].prepareToPlay()
            }
            
            // ===========================
            // Mach1 Decode Setup
            // ===========================
            // Setup the correct angle convention for orientation Euler input angles
            // オイラー入力角度に正しい角度規則を設定する。
            m1Decode.setPlatformType(type: Mach1PlatformiOS)
            // Setup the expected spatial audio mix format for decoding
            // デコード時に想定される空間音声のミックス形式を設定する。
            m1Decode.setDecodeAlgoType(newAlgorithmType: Mach1DecodeAlgoSpatial)
            // Setup for the safety filter speed:
            // セーフティーフィルターの回転数の設定
            //1.0 = no filter | 0.1 = slow filter
            m1Decode.setFilterSpeed(filterSpeed: 0.95)

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
        
        //Static Stereo
        do{
            stereoPlayer = try AVAudioPlayer(contentsOf: URL.init(fileURLWithPath: Bundle.main.path(forResource: "stereo", ofType: "wav")!))
        } catch {
            print(error)
        }
        stereoPlayer.prepareToPlay()
        print(stereoPlayer)
        
        //TODO: split audio channels for independent coeffs from our lib
        //let channelCount = audioPlayer.numberOfChannels
        //print("Channel Count: ", channelCount)
        
        //Allow audio to play when app closes
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback)
        } catch {
            print(error)
        }


        /// This example declares 2 motion managers:
        /// `headphoneMotionManager` is for headphone IMU enalbed device
        /// `motionManager` is for the native device's IMU
        /// `bUseHeadphones` lazily swaps between both manager's orientation updates

        /// この例では、2つのモーションマネージャを宣言しています。
        /// `headphoneMotionManager` は、ヘッドフォン IMU 搭載デバイス用です。
        /// `motionManager` はネイティブデバイスの IMU 用のものです。
        /// `bUseHeadphones` は、両方のマネージャのオリエンテーションの更新を遅延して切り替えます。

        motionManager = CMMotionManager()
        headphoneMotionManager = CMHeadphoneMotionManager()
        headphoneMotionManager.delegate = self    
        if motionManager.isDeviceMotionAvailable == true {
            motionManager.deviceMotionUpdateInterval = 0.01
            let queue = OperationQueue()
            /// Start native IMU core motion manager thread
            motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: queue, withHandler: { [weak self] (motion, error) -> Void in
                if (bUseHeadphoneOrientationData && headphoneMotionManager.isDeviceMotionAvailable){
                    headphoneMotionManager.startDeviceMotionUpdates(to: queue, withHandler: { [weak self] (headphonemotion, error) -> Void in
                        // Get the attitudes of the device
                        let quat = headphonemotion?.gaze(atOrientation: UIApplication.shared.statusBarOrientation)

                        // TODO: いる？いらない
                        let angles = getEuler(q1: quat!)
                        cameraYaw = angles.x
                        cameraPitch = angles.y
                        cameraRoll = angles.z
                    })
                    if (!headphoneMotionManager.isDeviceMotionActive) {
                        bUseHeadphoneOrientationData = false
                    } else {
                        // Get the attitudes of the device
                        let quat = motion?.gaze(atOrientation: UIApplication.shared.statusBarOrientation)

                        // TODO: いる？いらない？
                        let angles = getEuler(q1: quat!)
                        cameraYaw = angles.x
                        cameraPitch = angles.y
                        cameraRoll = angles.z
                    }
                }

                /// Warning:
                /// You're expected to correct and manage the orientation from devices in accordance with your UX
                /// to get accurate playback from Mach1Decode API
                /// https://dev.mach1.tech/#mach1-internal-angle-standard
                
                /// This example does not have motion management logic in place, it is expected
                /// that the app will be used in Portrait mode held in hand and will assume 0 values for
                /// yaw, pitch, roll upon launch. Rotating the device in portrait mode
                /// is the expected usage.

                /// 警告
                /// UXに合わせてデバイスからの向きを補正・管理することが求められる
                /// Mach1Decode APIから正確な再生を得るために
                /// https://dev.mach1.tech/#mach1-internal-angle-standard
                
                /// この例では、モーション管理ロジックを用意していません。アプリは手に持ってポートレートモードで使用し、
                /// 起動時にヨー、ピッチ、ロールの値を0とすることが想定されています。
                /// ポートレートモードでデバイスを回転させる が想定される使用方法です。


                // get & set values from UI
                // DispatchQueue -> 非同期処理
                DispatchQueue.main.async() {
                    self?.labelCameraYaw.text = String(m1obj.getCurrentAngle().x)
                    self?.labelCameraPitch.text = String(m1obj.getCurrentAngle().y)
                    self?.labelCameraRoll.text = String(m1obj.getCurrentAngle().z)
                    
                    // ここの x, y, z を flutter側から与える？
                    cameraPosition = Mach1Point3D(
                        x: (self?.sliderCameraX.value)! + cameraPositionOffset.x,
                        y: (self?.sliderCameraY.value)! + cameraPositionOffset.y,
                        z: (self?.sliderCameraZ.value)! + cameraPositionOffset.z
                    )
                }

                //Mute stereo if off
                if (stereoActive) {
                    stereoPlayer.setVolume(1.0, fadeDuration: 0.1)
                } else if (!stereoActive) {
                    stereoPlayer.setVolume(0.0, fadeDuration: 0.1)
                }

                // ここで位置情報から音声の設定をしてそう
                //Send device orientation to m1obj with the preferred algo
                m1obj.setListenerPosition(point: (cameraPosition))
                m1obj.setListenerRotation(point: Mach1Point3D(x: cameraYaw, y: cameraPitch, z: cameraRoll))
                m1obj.setDecoderAlgoPosition(point: (objectPosition))
                m1obj.setDecoderAlgoRotation(point: Mach1Point3D(x: 0, y: 0, z: 0))
                m1obj.setDecoderAlgoScale(point: Mach1Point3D(x: 0.1, y: 0.1, z: 0.1))
                //Setting: on/off yaw rotations from position
                m1obj.setUseYawForRotation(bool: isYawActive)
                //Setting: on/off pitch rotations from position
                m1obj.setUsePitchForRotation(bool: isPitchActive)
                //Setting: on/off roll rotations frok om position
                m1obj.setUseRollForRotation(bool: isRollActive)

                m1obj.evaluatePositionResults()


                // compute attenuation linear curve - project dist [0:1] to [1:0] interval
                // 減衰リニアカーブの計算 - 距離 [0:1] から [1:0] 区間への投影
                var attenuation : Float = m1obj.getDist()
                attenuation = mapFloat(value: attenuation, inMin: 0, inMax: 3, outMin: 1, outMax: 0)
                attenuation = clampFloat(value: attenuation, min: 0, max: 3)
                //m1obj.setUseAttenuation(useAttenuation: false)
                m1obj.setAttenuationCurve(attenuationCurve: attenuation)
                //print(attenuation)

                var decodeArray: [Float] = Array(repeating: 0.0, count: 18)
                m1obj.getCoefficients(result: &decodeArray)
                //print(decodeArray)
                
                //Use each coeff to decode multichannel Mach1 Spatial mix
                for i in 0...7 {
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

