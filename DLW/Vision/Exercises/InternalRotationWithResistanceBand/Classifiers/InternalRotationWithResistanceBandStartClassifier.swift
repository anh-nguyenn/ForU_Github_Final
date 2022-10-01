import Foundation
import Vision

struct InternalRotationWithResistanceBandStartClassifier: Classifier {
    static func check(observation: VNHumanBodyPoseObservation) -> Bool {
        var points: [VNPoint] = []
        
        // Calibration of the image is basically asking them to move backwards sufficiently
        let internalRotationWithResistanceBandModel: InternalRotationWithResistanceBandModel = InternalRotationWithResistanceBandModel.shared
        let calibrationJoints: [VNHumanBodyPoseObservation.JointName]
        
        // joints must be captured
        if internalRotationWithResistanceBandModel.side == .left || (internalRotationWithResistanceBandModel.currentSide == .left && internalRotationWithResistanceBandModel.side == .both) {
            calibrationJoints = [
                .rightShoulder,
                .rightWrist,
                .rightElbow,
                .leftShoulder
            ]
        } else {
            calibrationJoints = [
                .leftShoulder,
                .leftWrist,
                .leftElbow,
                .rightShoulder
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
        if internalRotationWithResistanceBandModel.calibrationFrames > 180 {
            internalRotationWithResistanceBandModel.calibrationFrames = 0
            return true
        } else {
            internalRotationWithResistanceBandModel.calibrationFrames += 1
            return false
        }
    }
}
