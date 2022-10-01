//
//  AudioManager.swift
//  DLW
//
//  Created by Que An Tran on 1/10/22.
//

import AVFoundation

/// Helper class to manage the Audio of the application.
class AudioManager {
    /// Singleton Audio manager.
    static let sharedAudioPlayer = AudioManager()
    /// Main synthesizer used for Text-to-Speech.
    static let sharedSynthesizer = AVSpeechSynthesizer()
    /// Main Audio player to play sound files.
    var audioPlayer: AVAudioPlayer?
    
    /// Plays .mp3 files using the `AVAudioPlayer`
    ///
    /// - parameters:
    ///     - url: The file path of the sound file to be played
    func play(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            audioPlayer?.play()
        } catch let error {
            print("Sound Play Error -> \(error)")
        }
    }
    /// Speaks the given text string.
    ///
    /// - parameters:
    ///     - text: Text to be spoken
    static func speakText(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        var voiceToUse: AVSpeechSynthesisVoice?
        for voice in AVSpeechSynthesisVoice.speechVoices() {
            if #available(iOS 9.0, *) {
                if voice.name == "Nicky"{
                    voiceToUse = voice
                }
            }
        }
        utterance.voice = voiceToUse
        if sharedSynthesizer.isSpeaking {
            sharedSynthesizer.stopSpeaking(at: .immediate)
        }
        sharedSynthesizer.speak(utterance)
    }
    
    /// Stops all sounds currently being played.
    static func stopAll() {
        if sharedSynthesizer.isSpeaking {
            sharedSynthesizer.stopSpeaking(at: .immediate)
        }
        if let player = sharedAudioPlayer.audioPlayer {
            if player.isPlaying {
                player.stop()
            }
        }
    }
}

