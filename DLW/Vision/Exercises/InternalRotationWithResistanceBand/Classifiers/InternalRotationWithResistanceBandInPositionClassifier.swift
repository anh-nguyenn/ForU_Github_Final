import Foundation
import Vision

struct InternalRotationWithResistanceBandInPositionClassifier: Classifier {
    static func check(observation: VNHumanBodyPoseObservation) -> Bool {
        let internalRotationWithResistanceBandModel: InternalRotationWithResistanceBandModel = InternalRotationWithResistanceBandModel.shared
        let calibrationJoints: [VNHumanBodyPoseObservation.JointName]
        let shoulderJoint: VNHumanBodyPoseObservation.JointName
        let wristJoint: VNHumanBodyPoseObservation.JointName
        let opShoulderJoint: VNHumanBodyPoseObservation.JointName
        let elbowJoint: VNHumanBodyPoseObservation.JointName
        // joints must be captured
        if internalRotationWithResistanceBandModel.side == .left || (internalRotationWithResistanceBandModel.currentSide == .left && internalRotationWithResistanceBandModel.side == .both) {
            calibrationJoints = [
                .rightShoulder,
                .rightWrist,
                .rightElbow,
                .leftShoulder
            ]
            shoulderJoint = .rightShoulder
            wristJoint = .rightWrist
            elbowJoint = .rightElbow
            opShoulderJoint = .leftShoulder
        } else {
            calibrationJoints = [
                .leftShoulder,
                .leftWrist,
                .leftElbow,
                .rightShoulder
            ]
            shoulderJoint = .leftShoulder
            wristJoint = .leftWrist
            elbowJoint = .leftElbow
            opShoulderJoint = .rightShoulder
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
        
        // Check that essential points are in the frame as we will accept if the opp ear is not in the frame
        if points[shoulderJoint] == nil || points[opShoulderJoint] == nil || points[wristJoint] == nil {
            return false
        }
        
        var armToOpShoulderAngle: Double
        armToOpShoulderAngle = getAngleFromThreeVNPoints(a: points[opShoulderJoint]!, b: points[shoulderJoint]!, c: points[wristJoint]!)
        var armAngle: Double
        armAngle = getAngleFromThreeVNPoints(a: points[shoulderJoint]!, b: points[elbowJoint]!, c: points[wristJoint]!)

        // Check if arm is placed properly
        if armAngle < 50 || armAngle > 160 {
            return false
        }
        if armToOpShoulderAngle < 120 {
            return false
        }
        
        // Capture the last exact angle
        if internalRotationWithResistanceBandModel.calibrationFrames > 20 {
            internalRotationWithResistanceBandModel.calibrationFrames = 0
            internalRotationWithResistanceBandModel.lastAngle = armToOpShoulderAngle
            return true
        } else {
            internalRotationWithResistanceBandModel.calibrationFrames += 1
            return false
        }
    }
}
