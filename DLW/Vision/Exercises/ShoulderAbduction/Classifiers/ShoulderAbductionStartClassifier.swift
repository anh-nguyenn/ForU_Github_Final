import Foundation
import Vision

struct ShoulderAbductionStartClassifier: Classifier {
    static func check(observation: VNHumanBodyPoseObservation) -> Bool {
        var points: [VNPoint] = []
        
        // Calibration of the image is basically asking them to move backwards sufficiently
        let shoulderAbductionModel: ShoulderAbductionModel = ShoulderAbductionModel.shared
        let calibrationJoints: [VNHumanBodyPoseObservation.JointName]
        
        // joints must be captured
        if shoulderAbductionModel.side == .left || (shoulderAbductionModel.currentSide == .left && shoulderAbductionModel.side == .both) {
            calibrationJoints = [
                .leftKnee,
                .leftShoulder,
                .rightShoulder,
                .rightWrist,
                .rightElbow,
                .rightHip,
                .rightKnee
                
            ]
        } else {
            calibrationJoints = [
                .rightKnee,
                .rightShoulder,
                .leftShoulder,
                .leftWrist,
                .leftElbow,
                .leftHip,
                .leftKnee
            ]
        }
        
        for joint in calibrationJoints {
            guard let point =
                    try? observation.recognizedPoint(joint), point.confidence > GlobalSettings.getDefaultConfidence() else { continue }
            points.append(point)
        }
        
        // Check if there are sufficient points
        if points.count < calibrationJoints.count {
            return false
        }
        
        return true
    }
}
