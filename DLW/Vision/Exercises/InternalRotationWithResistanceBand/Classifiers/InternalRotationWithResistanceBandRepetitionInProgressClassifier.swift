import Foundation
import Vision

struct InternalRotationWithResistanceBandRepetitionInProgressClassifier: Classifier {
    static func check(observation: VNHumanBodyPoseObservation) -> Bool {
        let internalRotationWithResistanceBandModel: InternalRotationWithResistanceBandModel = InternalRotationWithResistanceBandModel.shared
        let calibrationJoints: [VNHumanBodyPoseObservation.JointName]
        let shoulderJoint: VNHumanBodyPoseObservation.JointName
        let wristJoint: VNHumanBodyPoseObservation.JointName
        let opShoulderJoint: VNHumanBodyPoseObservation.JointName

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

        if armToOpShoulderAngle >= internalRotationWithResistanceBandModel.lastAngle - internalRotationWithResistanceBandModel.leeway && armToOpShoulderAngle <= internalRotationWithResistanceBandModel.lastAngle + internalRotationWithResistanceBandModel.leeway {
            internalRotationWithResistanceBandModel.currentAngleFrames += 1
            return true
        } else {
            internalRotationWithResistanceBandModel.currentAngleFrames = 0
            
            // Check that arms is rotating inwards
            if armToOpShoulderAngle > internalRotationWithResistanceBandModel.lastAngle + 3 {
                internalRotationWithResistanceBandModel.repetitionIsGood = false
                return false
            }
        }
        if armToOpShoulderAngle >= internalRotationWithResistanceBandModel.lastAngle - 2 || armToOpShoulderAngle <= internalRotationWithResistanceBandModel.lastAngle + 2 {
            internalRotationWithResistanceBandModel.lastAngle = armToOpShoulderAngle
        }
        
        internalRotationWithResistanceBandModel.repetitionIsGood = true
        return true
    }
}
