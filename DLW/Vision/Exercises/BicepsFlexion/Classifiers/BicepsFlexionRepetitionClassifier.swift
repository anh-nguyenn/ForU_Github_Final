import Foundation
import Vision

struct BicepsFlexionRepetitionClassifier: Classifier {
    static func check(observation: VNHumanBodyPoseObservation) -> Bool {
        let bicepsFlexionModel: BicepsFlexionModel = BicepsFlexionModel.shared
        let calibrationJoints: [VNHumanBodyPoseObservation.JointName]
        
        // KneeJoint is not considered as the point may jitter when the arm passes over it during the repetition
        let shoulderJoint: VNHumanBodyPoseObservation.JointName
        let hipJoint: VNHumanBodyPoseObservation.JointName
        let elbowJoint: VNHumanBodyPoseObservation.JointName
        let wristJoint: VNHumanBodyPoseObservation.JointName
        let ankleJoint: VNHumanBodyPoseObservation.JointName
        
        // points must be captured
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
            return false
        }
        
        // Check if the user is turned 90 degrees
        if bicepsFlexionModel.side == .left || (bicepsFlexionModel.side == .both && bicepsFlexionModel.currentSide == .left) {
            if !vnPointsAreHorizontallySortedAscendingly(points: [points[hipJoint]!, points[ankleJoint]!]) {
                return false
            }
        } else if bicepsFlexionModel.side == .right || (bicepsFlexionModel.side == .both && bicepsFlexionModel.currentSide == .right) {
            if !vnPointsAreHorizontallySortedAscendingly(points: [points[ankleJoint]!, points[hipJoint]!]) {
                return false
            }
        }
        
        let armAngle: Double = getAngleFromThreeVNPoints(a: points[wristJoint]!, b: points[elbowJoint]!, c: points[shoulderJoint]!)
        
        // Check that arms are moving up and that the angle recorded is not due to point jittering, causing the angle to shoot up very fast
        if armAngle > bicepsFlexionModel.lastAngle - 5  {
            return false
        }
        
        bicepsFlexionModel.lastAngle = armAngle
        return true
    }
}
