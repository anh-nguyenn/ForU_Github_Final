//
//  Constants.swift
//  DLW
//
//  Created by Que An Tran on 1/10/22.
//

struct Constants {
    
    struct Keychain {
        static let KeychainService: String = "authentication"
        static let KeychainAccount: String = "kimia-move"
    }
    
    struct Angles {
        
        // SKEE calibration angles
        static let HipKneeAnkleMaximumAngle: Double = 160
        static let ShoulderHipKneeMaximumAngle: Double = 130
        static let GoodHipKneeAnkleAngle: Double = 165 // Hip-Knee-Ankle should be > this angle5
        
        // OHTS calibration angles
        static let ElbowShoulderShoulderAngle: Double = 140
        static let LargeWristElbowShoulderAngle: Double = 145
        
        // OHSS calibration angles
        static public var AngleThreshold: Double = 90
        static public var GoodAngleThreshold: Double = 140
        
        // Side Stretch calibration angles
        static let CombinedLateralAngleThreshold: Double = 310
        static let CalibrationArmAngleThreshold: Double = 100
        static let RepetitionArmAngleThreshold: Double = 110
    }
    
    struct AngleFactors {
        // SKEE scaling factors as dependent on the Shoulder-Hip-Knee angle
        static let BaseShoulderHipAnkleAngleFactor: Double = 1.15
        static let GoodShoulderHipAnkleAngleFactor: Double = 1.07
        
        // OHTS scaling factors
        static public let WristAllowanceScalingFactor: Double = 0.2
    }
    
    struct Durations {
        // Demo Stretch durations
        static let DemoDuration: Float = 5
        static let DemoRepetitionDuration: Float = 5.5
        
        // SKEE durations
        static let RepetitionDuration: Float = 10
        static let CountdownDuration: Float = 3
        static let RepetitionBufferDuration: Double = 3
        static let PositionCountdownDuration: Float = 3
        
        // OHTS durations
        static let OHTSDuration: Float = 5
        
        // OHSS durations
        static let OHSSDuration: Float = 5.5
        
        // Side Stretch durations
        static let SSPositionCountdownDuration: Float = 3
        static let SSRepetitionDuration: Float = 5.5
    }
    
    struct Intervals {
        // Speech: Text-To-Speech played
        // Notification: Live Message displayed (and/or) Notification Sound played
        
        // Demo intervals
        static let DemoSpeechInterval: Double = 10
        static let DemoNotificationInterval: Double = 1
        
        // SKEE intervals
        static let SpeechInterval: Double = 2
        static let NotificationInterval: Double = 0.5
        
        // OHTS intervals
        static let OHTSSpeechInterval: Double = 6
        static let OHTSRepetitionCompletedInterval: Double = 3
        static let OHTSStretchStartInterval: Double = 6
        static let OHTSNotificationInterval: Double = 1 //   Minimum interval between playing notification sounds (e.g ding)
        static let OHTSTransitionInterval: Double = 1 //     Minimum interval between switching between a good and bad repetition
        static let OHTSInstructionInterval: Double = 2 //    Minimum interval between changing the instructional messages
        
        // OHSS Intervals
        static let OHSSSpeechInterval: Double = 4
        static let OHSSNotificationInterval: Double = 1
        static let OHSSTransitionInterval: Double = 0.5
        static let OHSSStartInterval: Float = 3
        static let OHSSRepetitionBufferInterval: Double = 3
        
        // Side Stretch Intervals
        static let SSSpeechInterval: Double = 10
        static let SSNotificationInterval: Double = 0.5
    }
}
