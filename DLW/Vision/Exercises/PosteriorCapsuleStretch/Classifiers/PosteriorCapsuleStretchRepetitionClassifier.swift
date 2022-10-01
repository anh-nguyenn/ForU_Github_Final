import Foundation
import Vision

struct PosteriorCapsuleStretchRepetitionClassifier: Classifier {
    
    static func check(observation: VNHumanBodyPoseObservation) -> Bool {
        let posteriorCapsuleStretchModel: PosteriorCapsuleStretchModel = PosteriorCapsuleStretchModel.shared
        let joints: [VNHumanBodyPoseObservation.JointName]
        
        // joints must be captured
        if posteriorCapsuleStretchModel.side == .left || (posteriorCapsuleStretchModel.currentSide == .left && posteriorCapsuleStretchModel.side == .both) {
            joints = [
                .leftShoulder,
                .leftElbow,
                .leftWrist,
                .leftHip,
            ]
        } else {
            joints = [
                .rightShoulder,
                .rightElbow,
                .rightWrist,
                .rightHip,
            ]
        }
        
        var points: [VNHumanBodyPoseObservation.JointName : VNRecognizedPoint] = [:]
        
        for joint in joints {
            guard let point =
                    try? observation.recognizedPoint(joint), point.confidence > GlobalSettings.getDefaultConfidence() else { continue }
            points[joint] = point
        }
        
        // Check if there are sufficient points
        if points.count < joints.count - 1 {
            return false
        }
        
        return true
    }
}
