import Foundation
import Vision

struct ShoulderAbductionRepetitionClassifier: Classifier {
    static func check(observation: VNHumanBodyPoseObservation) -> Bool {
        let shoulderAbductionModel: ShoulderAbductionModel = ShoulderAbductionModel.shared
        let calibrationJoints: [VNHumanBodyPoseObservation.JointName]
        let shoulderJoint: VNHumanBodyPoseObservation.JointName
        let hipJoint: VNHumanBodyPoseObservation.JointName
        let elbowJoint: VNHumanBodyPoseObservation.JointName
        let wristJoint: VNHumanBodyPoseObservation.JointName
        
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
            shoulderJoint = .rightShoulder
            hipJoint = .rightHip
            elbowJoint = .rightElbow
            wristJoint = .rightWrist
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
            shoulderJoint = .leftShoulder
            hipJoint = .leftHip
            elbowJoint = .leftElbow
            wristJoint = .leftWrist
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
        
        var armToHipAngle: Double
        armToHipAngle = getAngleFromThreeVNPoints(a: points[wristJoint]!, b: points[shoulderJoint]!, c: points[hipJoint]!)
        
        // Check if the arms are in the right direction
        if shoulderAbductionModel.side == .left || (shoulderAbductionModel.side == .both && shoulderAbductionModel.currentSide == .left) {
            if !vnPointsAreHorizontallySortedAscendingly(points: [points[wristJoint]!, points[elbowJoint]!, points[shoulderJoint]!]) {
                return false
            }
        } else {
            if !vnPointsAreHorizontallySortedAscendingly(points: [points[shoulderJoint]!, points[elbowJoint]!, points[wristJoint]!]) {
                return false
            }
        }
        
        // Check that arms are moving up and that the angle recorded is not due to point jittering, causing the angle to shoot up very fast
        if armToHipAngle < shoulderAbductionModel.lastAngle + 20 {
            return false
        }
        
        shoulderAbductionModel.lastAngle = armToHipAngle
        return true
    }
}
