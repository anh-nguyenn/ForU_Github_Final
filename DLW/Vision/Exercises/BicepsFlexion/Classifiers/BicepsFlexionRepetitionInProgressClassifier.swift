import Foundation
import Vision

struct BicepsFlexionRepetitionInProgressClassifier: Classifier {
    static func check(observation: VNHumanBodyPoseObservation) -> Bool {
        let bicepsFlexionModel: BicepsFlexionModel = BicepsFlexionModel.shared
        let calibrationJoints: [VNHumanBodyPoseObservation.JointName]
        
        // KneeJoint is not considered as the point may jitter when the arm passes over it during the repetition
        let shoulderJoint: VNHumanBodyPoseObservation.JointName
        let hipJoint: VNHumanBodyPoseObservation.JointName
        let elbowJoint: VNHumanBodyPoseObservation.JointName
        let wristJoint: VNHumanBodyPoseObservation.JointName
        let ankleJoint: VNHumanBodyPoseObservation.JointName
        
        // joints must be captured
        if bicepsFlexionModel.side == .left || (bicepsFlexionModel.currentSide == .left && bicepsFlexionModel.side == .both) {
            calibrationJoints = [
                .rightShoulder,
                .rightWrist,
                .rightElbow,
                .rightHip,
                .rightAnkle
            ]
            shoulderJoint = .rightShoulder
            hipJoint = .rightHip
            elbowJoint = .rightElbow
            wristJoint = .rightWrist
            ankleJoint = .rightAnkle
        } else {
            calibrationJoints = [
                .leftShoulder,
                .leftWrist,
                .leftElbow,
                .leftHip,
                .leftAnkle
            ]
            shoulderJoint = .leftShoulder
            hipJoint = .leftHip
            elbowJoint = .leftElbow
            wristJoint = .leftWrist
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
            bicepsFlexionModel.repetitionIsGood = false
            return false
        }
        
        // Check if the user is turned 90 degrees
        if bicepsFlexionModel.side == .left || (bicepsFlexionModel.side == .both && bicepsFlexionModel.currentSide == .left) {
            if !vnPointsAreHorizontallySortedAscendingly(points: [points[hipJoint]!, points[ankleJoint]!]) {
                bicepsFlexionModel.repetitionIsGood = false
                return false
            }
        } else if bicepsFlexionModel.side == .right || (bicepsFlexionModel.side == .both && bicepsFlexionModel.currentSide == .right) {
            if !vnPointsAreHorizontallySortedAscendingly(points: [points[ankleJoint]!, points[hipJoint]!]) {
                bicepsFlexionModel.repetitionIsGood = false
                return false
            }
        }
        
        let armAngle: Double = getAngleFromThreeVNPoints(a: points[wristJoint]!, b: points[elbowJoint]!, c: points[shoulderJoint]!)
        
        if armAngle >= bicepsFlexionModel.lastAngle - bicepsFlexionModel.leeway && armAngle <= bicepsFlexionModel.lastAngle + bicepsFlexionModel.leeway {
            bicepsFlexionModel.currentAngleFrames += 1
            bicepsFlexionModel.repetitionIsGood = true
            return true
        } else {
            bicepsFlexionModel.currentAngleFrames = 0
            
            // Check that arms are always going up
            if armAngle > bicepsFlexionModel.lastAngle + 2 {
                bicepsFlexionModel.repetitionIsGood = false
                return false
            }
        }
        if armAngle >= bicepsFlexionModel.lastAngle - 2 || armAngle <= bicepsFlexionModel.lastAngle + 2 {
            bicepsFlexionModel.lastAngle = armAngle
        }
        
        bicepsFlexionModel.repetitionIsGood = true
        return true
    }
}
