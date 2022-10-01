//
//  Commons.swift
//  DLW
//
//  Created by Que An Tran on 1/10/22.
//

import Foundation
import UIKit


/// Contains all the Global Settings based on the email of the user using the application at the moment
class GlobalSettings: ObservableObject {
   
    /// Overall confidence to be used to detect `Hand Poses` from `Vision`.
    static var overallConfidence: Float = getDefaultConfidence()
    
    /// Updates the saved settings.
    static func updateGlobalSettings() {
        let defaults = UserDefaults.standard
        let newConfidence = defaults.float(forKey: getDefaultEmail() + "ConfidenceValue")
        if newConfidence == 0 {
            overallConfidence = 0.3
        } else {
            overallConfidence = newConfidence
        }
    }
    /// Gets the cached email of the user currently using the application.
    static func getDefaultEmail() -> String {
        let defaults = UserDefaults.standard
        let email: String
        if let tempEmail = defaults.string(forKey: "savedEmail") { email = tempEmail }
        else { email = "emptyEmail" }
        return email
    }
    /// Gets the cached default confidence value to be used to detect `Hand Poses` from `Vision`.
    static func getDefaultConfidence() -> Float {
        let defaults = UserDefaults.standard
        return defaults.float(forKey: getDefaultEmail() + "ConfidenceValue") == 0 ? 0.2 : defaults.float(forKey: getDefaultEmail() + "ConfidenceValue")
    }
    
    // TODO: update plszxc
    static func getDefaultInFrameLikelihood() -> Float {
        return 0.4
    }
}

 
///
/// General rule of thumb is to keep Text-To-Speech to a maximum of 1 sentence.
/// In the future can substitute with https://cloud.google.com/text-to-speech
struct TextToSpeech {
    
    // Welcome Messages
    static let welcomeBicepFlexionWithResistanceBand: String = "Bicep Flexion with Resistance Band."
    static let welcomeMessageBandedRotation: String = "Banded Rotation with Scapular Retraction."
    static let welcomeMessageShoulderAbductionWithResistanceBand = "Shoulder Abduction with Resistance Band."
    static let welcomeMessageShoulderFlexion: String = "Shoulder Flexion with Resistance Band."
    static let welcomeMessageShoulderHorizontalAbductionWithResistanceBand: String = "Shoulder Horizontal Abduction with Resistance Band."
    static let welcomeMessagePosteriorCapsuleStretch: String = "Posterior Capsule Stretch."
    static let welcomeMessageExternalRotationWithResistanceBand: String = "External Rotation with Resistance Band."
    static let welcomeMessageShoulderExtensionWithResistanceBand: String = "Shoulder Extension with Resistance Band."
    static let welcomeMessageInternalRotationWithResistanceBand: String = "Internal Rotation with Resistance Band"
    
    // Knee Welcome Messages
    static let welcomeMessageStandingKneeBend: String = "Standing Knee Bend"
    static let welcomeMessageAssistedKneeFlexion: String = "Assisted Knee Flexion"
    static let welcomeMessageAssistedKneeExtension: String = "Assisted Knee Extension"
    
    // General Instructions
    static let exerciseIsStarting: String = "Please Standby, Exercise starting"

    // Completion Messages
    static let goodWithRelax: String = "Good! Now relax"
    static let goodExercise: String = "Good job on completing the exercise"
    static let goodJob: String = "Good job on completing all exercises! Here is a summary of your results."
    static let doNotGiveUp = "Don't give up. Try your best."
}

