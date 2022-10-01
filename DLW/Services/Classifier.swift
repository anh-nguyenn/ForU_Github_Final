//
//  Classifier.swift
//  DLW
//
//  Created by Que An Tran on 1/10/22.
//

import Foundation
import Vision
import MLKit

/// Helper class to ensure perform checks for various states by analysing the observation given.
///
/// Helps to check if it is able to enter into the next state.
/// The naming is in the format <Move Name><State to Enter>Classifier.
protocol Classifier {
    
    /// Checks if the observation satisfies the conditions required to transition into the State to Enter.
    ///
    /// - Parameters:
    ///    - observation: `VNHumanBodyPoseObservation` from the image detected by the device.
    static func check(observation: VNHumanBodyPoseObservation) -> Bool
}

protocol PoseClassifier {
    
    /// Checks if the observation satisfies the conditions required to transition into the State to Enter.
    ///
    /// - Parameters:
    ///    - observation: `Pose` from the image detected by the device.
    static func check(pose: Pose) -> Bool
}
