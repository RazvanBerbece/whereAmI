//
//  texttospeech.swift
//  whereAmI?
//
//  Created by Razvan-Antonio Berbece on 26/04/2020.
//  Copyright © 2020 Razvan-Antonio Berbece. All rights reserved.
//

import Foundation
import AVFoundation

class Speaker: NSObject {
    let synth = AVSpeechSynthesizer()
    
    override init() {
        super.init()
        synth.delegate = self
    }
    
    func toSpeech(_ string: String) {
        let utterance = AVSpeechUtterance(string: string)
        synth.speak(utterance)
    }
}

extension Speaker: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("Finished TTS toSpeech().")
    }
}
