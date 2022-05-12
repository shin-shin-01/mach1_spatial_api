//
//  EncoderView
//  mach1-ios-encodeDecode-example
//
//  Created by User on 16/04/2019.
//  Copyright © 2019 User. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import SceneKit
import Mach1SpatialAPI


class Encoder {
    var players: [AVAudioPlayer] = [AVAudioPlayer(), AVAudioPlayer()]
    
    func setupPlayers(audioFilePath: String) -> [AVAudioPlayer] {
        players = [AVAudioPlayer(), AVAudioPlayer()]
        try! players[0] = AVAudioPlayer(contentsOf: URL.init(fileURLWithPath: audioFilePath))
        try! players[1] = AVAudioPlayer(contentsOf: URL.init(fileURLWithPath: audioFilePath))
        
        players[0].pan = -1.0
        players[1].pan = 1.0
        
        players[0].volume = 0.0
        players[1].volume = 0.0
        
        players[0].prepareToPlay()
        players[1].prepareToPlay()
        
        players[0].numberOfLoops = -1
        players[1].numberOfLoops = -1
        
        players[0].isMeteringEnabled = true
        players[1].isMeteringEnabled = true

        return players;
   }
}
