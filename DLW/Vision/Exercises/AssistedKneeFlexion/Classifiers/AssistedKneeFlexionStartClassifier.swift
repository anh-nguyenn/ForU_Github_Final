import Foundation
import Vision

struct AssistedKneeFlexionStartClassifier: Classifier {
    static func check(observation: VNHumanBodyPoseObservation) -> Bool {

        // Calibration of the image is basically asking them to move backwards sufficiently
        let assistedKneeFlexionModel: AssistedKneeFlexionModel = AssistedKneeFlexionModel.shared
        let calibrationJoints: [VNHumanBodyPoseObservation.JointName]
        
        // joints must be captured
        if assistedKneeFlexionModel.side == .left || (assistedKneeFlexionModel.currentSide == .left && assistedKneeFlexionModel.side == .both) {
            calibrationJoints = [
                .rightHip,
                .rightKnee,
                .rightAnkle,
            ]
        } else {
            calibrationJoints = [
                .leftHip,
                .leftKnee,
                .leftAnkle,
            ]
        }
        
        var points: [VNHumanBodyPoseObservation.JointName : VNRecognizedPoint] = [:]
        
        for joint in calibrationJoints {
            guard let point =
                    try? observation.recognizedPoint(joint), point.confidence > GlobalSettings.getDefaultConfidence() else { continue }
            points[joint] = point
        }
        
        // Check if there are sufficient points
        if points.count < calibrationJoints.count {
            return false
        }
        
        return true
    }
}



