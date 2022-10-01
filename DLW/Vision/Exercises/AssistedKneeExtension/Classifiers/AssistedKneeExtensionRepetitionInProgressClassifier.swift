import Foundation
import Vision

struct AssistedKneeExtensionRepetitionInProgressClassifier: Classifier {
    static func check(observation: VNHumanBodyPoseObservation) -> Bool {
        let assistedKneeExtensionModel: AssistedKneeExtensionModel = AssistedKneeExtensionModel.shared
        let calibrationJoints: [VNHumanBodyPoseObservation.JointName]
        let hipJoint: VNHumanBodyPoseObservation.JointName
        let kneeJoint: VNHumanBodyPoseObservation.JointName
        let ankleJoint: VNHumanBodyPoseObservation.JointName
        
        // joints must be captured
        if assistedKneeExtensionModel.side == .left || (assistedKneeExtensionModel.currentSide == .left && assistedKneeExtensionModel.side == .both) {
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
            assistedKneeExtensionModel.repetitionIsGood = false
            return false
        }
        
        let legAngle: Double = getAngleFromThreeVNPoints(a: points[hipJoint]!, b: points[kneeJoint]!, c: points[ankleJoint]!)

        if legAngle >= assistedKneeExtensionModel.lastAngle - assistedKneeExtensionModel.leeway && legAngle <= assistedKneeExtensionModel.lastAngle + assistedKneeExtensionModel.leeway {
            assistedKneeExtensionModel.currentAngleFrames += 1
            return true
        } else {
            assistedKneeExtensionModel.currentAngleFrames = 0
            
            // Check that arms are always going up
            if legAngle < assistedKneeExtensionModel.lastAngle - 3 {
                assistedKneeExtensionModel.repetitionIsGood = false
                return false
            }
        }
        
        if legAngle >= assistedKneeExtensionModel.lastAngle - 2 || legAngle <= assistedKneeExtensionModel.lastAngle + 2 {
            assistedKneeExtensionModel.lastAngle = legAngle
        }
        
        assistedKneeExtensionModel.repetitionIsGood = true
        return true
    }
}

