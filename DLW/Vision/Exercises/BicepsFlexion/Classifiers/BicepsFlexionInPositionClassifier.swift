import Foundation
import Vision

struct BicepsFlexionInPositionClassifier: Classifier {
    static func check(observation: VNHumanBodyPoseObservation) -> Bool {
        let bicepsFlexionModel: BicepsFlexionModel = BicepsFlexionModel.shared
        let calibrationJoints: [VNHumanBodyPoseObservation.JointName]
        let shoulderJoint: VNHumanBodyPoseObservation.JointName
        let hipJoint: VNHumanBodyPoseObservation.JointName
        let elbowJoint: VNHumanBodyPoseObservation.JointName
        let wristJoint: VNHumanBodyPoseObservation.JointName
        let kneeJoint: VNHumanBodyPoseObservation.JointName
        let ankleJoint: VNHumanBodyPoseObservation.JointName
        
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
            shoulderJoint = .rightShoulder
            hipJoint = .rightHip
            elbowJoint = .rightElbow
            wristJoint = .rightWrist
            kneeJoint = .rightKnee
            ankleJoint = .rightAnkle
        } else {
            calibrationJoints = [
                .leftShoulder,
                .leftWrist,
                .leftElbow,
                .leftHip,
                .leftKnee,
                .leftAnkle
            ]
            shoulderJoint = .leftShoulder
            hipJoint = .leftHip
            elbowJoint = .leftElbow
            wristJoint = .leftWrist
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
        
        // Check if the user is turned 90 degrees
        if bicepsFlexionModel.side == .left || (bicepsFlexionModel.side == .both && bicepsFlexionModel.currentSide == .left) {
            if !vnPointsAreHorizontallySortedAscendingly(points: [points[hipJoint]!, points[kneeJoint]!]) {
                return false
            }
        } else if bicepsFlexionModel.side == .right || (bicepsFlexionModel.side == .both && bicepsFlexionModel.currentSide == .right) {
            if !vnPointsAreHorizontallySortedAscendingly(points: [points[kneeJoint]!, points[hipJoint]!]) {
                return false
            }
        }
        
        // Check if arms are facing downwards
        if !vnPointsAreVerticallySortedAscendingly(points: [points[wristJoint]!, points[elbowJoint]!, points[shoulderJoint]!]) {
            return false
        }
        
        // Check if legs are ~90 degrees
        let legAngle: Double = getAngleFromThreeVNPoints(a: points[hipJoint]!, b: points[kneeJoint]!, c: points[ankleJoint]!)
        if legAngle > 105 || legAngle < 70 {
            return false
        }
        
        // Check if wrist is below knee
        if !vnPointsAreVerticallySortedAscendingly(points: [points[wristJoint]!, points[kneeJoint]!]) {
            return false
        }
        
        let armToHipAngle: Double = getAngleFromThreeVNPoints(a: points[elbowJoint]!, b: points[shoulderJoint]!, c: points[hipJoint]!)
        let armAngle: Double = getAngleFromThreeVNPoints(a: points[wristJoint]!, b: points[elbowJoint]!, c: points[shoulderJoint]!)
        
        // Check if arm is somewhat straight
        if armAngle < 140 {
            return false
        }
        
        // Only calibrate starting angle on first repetition
        if bicepsFlexionModel.firstRepetition {
            // if current angle is not within 1 degree of the last angle, arm is still moving to starting position
            if armToHipAngle < bicepsFlexionModel.lastAngle - 3 || armToHipAngle > bicepsFlexionModel.lastAngle + 3 {
                bicepsFlexionModel.currentAngleFrames = 0
                bicepsFlexionModel.lastAngle = armToHipAngle
                return false
            } else {
                // If the current angle is within 1 degree of the last angle, arm has to stay there for 30 frames and that angle will be considered the starting angle for the rest of the exercise
                
                bicepsFlexionModel.currentAngleFrames += 1
                if bicepsFlexionModel.currentAngleFrames >= 30 {
                    bicepsFlexionModel.startingAngle = armToHipAngle
                    bicepsFlexionModel.currentAngleFrames = 0
                    bicepsFlexionModel.lastAngle = armAngle
                    return true
                }
                return false
            }
        } else {
            // If its not the first repetition, no more calibration needed and will just compare to the starting angle
            if armToHipAngle < bicepsFlexionModel.startingAngle - 3 || armToHipAngle > bicepsFlexionModel.startingAngle + 3 {
                return false
            }
        }
        bicepsFlexionModel.lastAngle = armAngle
        return true
    }
}
