import Foundation
import Vision

struct ShoulderAbductionRepetitionInProgressClassifier: Classifier {
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
        
        var armToHipAngle: Double
        armToHipAngle = getAngleFromThreeVNPoints(a: points[wristJoint]!, b: points[shoulderJoint]!, c: points[hipJoint]!)

        if armToHipAngle >= shoulderAbductionModel.lastAngle - shoulderAbductionModel.leeway && armToHipAngle <= shoulderAbductionModel.lastAngle + shoulderAbductionModel.leeway {
            shoulderAbductionModel.currentAngleFrames += 1
            return true
        } else {
            shoulderAbductionModel.currentAngleFrames = 0
            
            // Check that arms are always going up
            if armToHipAngle < shoulderAbductionModel.lastAngle - 3 {
                shoulderAbductionModel.repetitionIsGood = false
                return false
            }
        }
        if armToHipAngle >= shoulderAbductionModel.lastAngle - 2 || armToHipAngle <= shoulderAbductionModel.lastAngle + 2 {
            shoulderAbductionModel.lastAngle = armToHipAngle
        }
        shoulderAbductionModel.repetitionIsGood = true
        return true
    }
}
