import Foundation
import Vision

struct ShoulderExtensionStartClassifier: Classifier {
    static func check(observation: VNHumanBodyPoseObservation) -> Bool {
        var points: [VNPoint] = []
        
        // Calibration of the image is basically asking them to move backwards sufficiently
        let shoulderExtensionModel: ShoulderExtensionModel = ShoulderExtensionModel.shared
        let calibrationJoints: [VNHumanBodyPoseObservation.JointName]
        
        // joints must be captured
        if shoulderExtensionModel.side == .left || (shoulderExtensionModel.currentSide == .left && shoulderExtensionModel.side == .both) {
            calibrationJoints = [
                .rightShoulder,
                .rightWrist,
                .rightElbow,
                .rightHip
                
            ]
        } else {
            calibrationJoints = [
                .leftShoulder,
                .leftWrist,
                .leftElbow,
                .leftHip
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
        
        // Waiting for audio
        if shoulderExtensionModel.calibrationFrames > 200 {
            shoulderExtensionModel.calibrationFrames = 0
            return true
        } else {
            shoulderExtensionModel.calibrationFrames += 1
            return false
        }
    }
}
