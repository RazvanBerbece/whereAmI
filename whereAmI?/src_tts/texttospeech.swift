//
//  texttospeech.swift
//  whereAmI?
//
//  Created by Razvan-Antonio Berbece on 26/04/2020.
//  Copyright © 2020 Razvan-Antonio Berbece. All rights reserved.
//

import Foundation
import AVFoundation

public class TextToSpeechManager { /** This manages the TTS processes in the app */
    
    public func toSpeech(text: String, delay: Double) {
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(identifier: "Karen")
        utterance.postUtteranceDelay = TimeInterval(delay) // ?
        // utterance.voice = AVSpeechSynthesisVoice(language: "ro-RO")
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
        
    }
    
}
