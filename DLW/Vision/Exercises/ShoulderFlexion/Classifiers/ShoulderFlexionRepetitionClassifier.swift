import Foundation
import Vision

struct ShoulderFlexionRepetitionClassifier: Classifier {
    static func check(observation: VNHumanBodyPoseObservation) -> Bool {
        let shoulderFlexionModel: ShoulderFlexionModel = ShoulderFlexionModel.shared
        let calibrationJoints: [VNHumanBodyPoseObservation.JointName]
        let shoulderJoint: VNHumanBodyPoseObservation.JointName
        let hipJoint: VNHumanBodyPoseObservation.JointName
        let wristJoint: VNHumanBodyPoseObservation.JointName
        let elbowJoint: VNHumanBodyPoseObservation.JointName
        
        // joints must be captured
        if shoulderFlexionModel.side == .left || (shoulderFlexionModel.currentSide == .left && shoulderFlexionModel.side == .both) {
            calibrationJoints = [
                .rightShoulder,
                .rightWrist,
                .rightElbow,
                .rightHip
            ]
            shoulderJoint = .rightShoulder
            hipJoint = .rightHip
            wristJoint = .rightWrist
            elbowJoint = .rightElbow
        } else {
            calibrationJoints = [
                .leftShoulder,
                .leftWrist,
                .leftElbow,
                .leftHip
            ]
            shoulderJoint = .leftShoulder
            hipJoint = .leftHip
            wristJoint = .leftWrist
            elbowJoint = .leftElbow
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
        
        let armToHipAngle: Double = getAngleFromThreeVNPoints(a: points[elbowJoint]!, b: points[shoulderJoint]!, c: points[hipJoint]!)
        let armAngle: Double = getAngleFromThreeVNPoints(a: points[wristJoint]!, b: points[elbowJoint]!, c: points[shoulderJoint]!)
        
        // Check that arms are more or less straight
        if armAngle < 140 {
            return false
        }
        
        // Check that arms are moving up and that the angle recorded is not due to point jittering, causing the angle to shoot up very fast
        if armToHipAngle < shoulderFlexionModel.lastAngle + 10 || armToHipAngle > shoulderFlexionModel.lastAngle + 20 {
            return false
        }
        
        // Check that the arms are moving in the correct direction
        if shoulderFlexionModel.side == .left || (shoulderFlexionModel.currentSide == .left && shoulderFlexionModel.side == .both) {
            if !vnPointsAreHorizontallySortedAscendingly(points: [points[shoulderJoint]!, points[elbowJoint]!, points[wristJoint]!]) {
                return false
            }
        } else {
            if !vnPointsAreHorizontallySortedAscendingly(points: [points[wristJoint]!, points[elbowJoint]!, points[shoulderJoint]!]) {
                return false
            }
        }
        
        shoulderFlexionModel.lastAngle = armToHipAngle
        return true
    }
}
