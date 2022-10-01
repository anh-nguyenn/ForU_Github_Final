import Foundation
import Vision

struct BicepsFlexionStartClassifier: Classifier {
    static func check(observation: VNHumanBodyPoseObservation) -> Bool {
        var points: [VNPoint] = []
        
        // Calibration of the image is basically asking them to move backwards sufficiently
        let bicepsFlexionModel: BicepsFlexionModel = BicepsFlexionModel.shared
        let calibrationJoints: [VNHumanBodyPoseObservation.JointName]
        
        // joints must be captured
        if bicepsFlexionModel.side == .left || (bicepsFlexionModel.currentSide == .left && bicepsFlexionModel.side == .both) {
            calibrationJoints = [
                .rightShoulder,
                .rightWrist,
                .rightElbow,
                .rightHip,
                .rightKnee,
                .rightAnkle
            ]
        } else {
            calibrationJoints = [
                .leftShoulder,
                .leftWrist,
                .leftElbow,
                .leftHip,
                .leftKnee,
                .leftAnkle
            ]
        }
        
        for joint in calibrationJoints {
            guard let point =
                    try? observation.recognizedPoint(joint), point.confidence > GlobalSettings.getDefaultConfidence() else { continue }
            points.append(point)
        }
        
        // Check where there are sufficient points
        if points.count < calibrationJoints.count {
            return false
        }
        
        return true
    }
    
}
