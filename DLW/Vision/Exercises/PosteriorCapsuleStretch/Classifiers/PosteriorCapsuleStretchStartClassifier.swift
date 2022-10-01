import Foundation
import Vision

struct PosteriorCapsuleStretchStartClassifier: Classifier {
    
    static func check(observation: VNHumanBodyPoseObservation) -> Bool {
        var points: [VNHumanBodyPoseObservation.JointName : VNRecognizedPoint] = [:]

        // Calibration of the image is basically asking them to move backwards sufficiently
        let posteriorCapsuleStretchModel: PosteriorCapsuleStretchModel = PosteriorCapsuleStretchModel.shared
        let calibrationJoints: [VNHumanBodyPoseObservation.JointName]
        
        // joints must be captured
        calibrationJoints = [
            .leftShoulder,
            .leftElbow,
            .leftWrist,
            .leftHip,
            .rightShoulder,
            .rightElbow,
            .rightWrist,
            .rightHip,
            ]
        
        for joint in calibrationJoints {
            guard let point =
                    try? observation.recognizedPoint(joint), point.confidence > GlobalSettings.getDefaultConfidence() else { continue }
            points[joint] = point
        }
        
        // Check if there are sufficient points
        if points.count < calibrationJoints.count {
            return false
        }
        
        // Buffer before transitioning state
        if posteriorCapsuleStretchModel.calibrationFrames > 80 {
            posteriorCapsuleStretchModel.calibrationFrames = 0
            return true
        } else {
            posteriorCapsuleStretchModel.calibrationFrames += 1
            return false
        }
    }
}
