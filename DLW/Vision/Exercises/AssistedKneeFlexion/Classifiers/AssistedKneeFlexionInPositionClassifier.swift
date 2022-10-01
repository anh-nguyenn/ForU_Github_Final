import Foundation
import Vision

struct AssistedKneeFlexionInPositionClassifier: Classifier {
    static func check(observation: VNHumanBodyPoseObservation) -> Bool {
        let assistedKneeFlexionModel: AssistedKneeFlexionModel = AssistedKneeFlexionModel.shared
        
        let calibrationJoints: [VNHumanBodyPoseObservation.JointName]
        let hipJoint: VNHumanBodyPoseObservation.JointName
        let kneeJoint: VNHumanBodyPoseObservation.JointName
        let ankleJoint: VNHumanBodyPoseObservation.JointName
        
        // joints must be captured
        if assistedKneeFlexionModel.side == .left || (assistedKneeFlexionModel.currentSide == .left && assistedKneeFlexionModel.side == .both) {
            calibrationJoints = [
                .rightHip,
                .rightKnee,
                .rightAnkle
            ]
            hipJoint = .rightHip
            kneeJoint = .rightKnee
            ankleJoint = .rightAnkle
        } else {
            calibrationJoints = [
                .leftHip,
                .leftKnee,
                .leftAnkle
            ]
            hipJoint = .leftHip
            kneeJoint = .leftKnee
            ankleJoint = .leftAnkle
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
        
        let legAngle: Double = getAngleFromThreeVNPoints(a: points[hipJoint]!, b: points[kneeJoint]!, c: points[ankleJoint]!)
        if legAngle > 105 || legAngle < 75{
            return false
        }
        
        assistedKneeFlexionModel.currentAngleFrames += 1
        if assistedKneeFlexionModel.currentAngleFrames >= 50 {
            assistedKneeFlexionModel.currentAngleFrames = 0
            assistedKneeFlexionModel.lastAngle = legAngle
            return true
        }
        return false
    }
}

