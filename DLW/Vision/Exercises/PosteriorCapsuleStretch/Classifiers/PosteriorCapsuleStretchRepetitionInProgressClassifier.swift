import Foundation
import Vision

struct PosteriorCapsuleStretchRepetitionInProgressClassifier: Classifier {
    
    static func check(observation: VNHumanBodyPoseObservation) -> Bool {
        let posteriorCapsuleStretchModel: PosteriorCapsuleStretchModel = PosteriorCapsuleStretchModel.shared
        let joints: [VNHumanBodyPoseObservation.JointName]
        
        let shoulderJoint: VNHumanBodyPoseObservation.JointName
        let hipJoint: VNHumanBodyPoseObservation.JointName
        let elbowJoint: VNHumanBodyPoseObservation.JointName
        let wristJoint: VNHumanBodyPoseObservation.JointName
        
        // joints must be captured
        if posteriorCapsuleStretchModel.side == .left || (posteriorCapsuleStretchModel.currentSide == .left && posteriorCapsuleStretchModel.side == .both) {
            joints = [
                .leftShoulder,
                .leftElbow,
                .leftWrist,
                .leftHip,
            ]
            shoulderJoint = .leftShoulder
            hipJoint = .leftHip
            elbowJoint = .leftElbow
            wristJoint = .leftWrist
        } else {
            joints = [
                .rightShoulder,
                .rightElbow,
                .rightWrist,
                .rightHip,
            ]
            shoulderJoint = .rightShoulder
            hipJoint = .rightHip
            elbowJoint = .rightElbow
            wristJoint = .rightWrist
        }
        
        var points: [VNHumanBodyPoseObservation.JointName : VNRecognizedPoint] = [:]
        
        for joint in joints {
            guard let point =
                    try? observation.recognizedPoint(joint), point.confidence > GlobalSettings.getDefaultConfidence() else { continue }
            points[joint] = point
        }
        
        // Check if there are sufficient points
        if points.count < joints.count {
            return false
        }
        
        // Check direction correct
        if posteriorCapsuleStretchModel.side == .left || (posteriorCapsuleStretchModel.currentSide == .left && posteriorCapsuleStretchModel.side == .both) {
            if !vnPointsAreHorizontallySortedAscendingly(points: [points[shoulderJoint]!, points[elbowJoint]!, points[wristJoint]!]) {
                return false
            }
        } else {
            if !vnPointsAreHorizontallySortedAscendingly(points: [points[wristJoint]!, points[elbowJoint]!, points[shoulderJoint]!]) {
                return false
            }
        }
        
        var armToHipAngle: Double
        armToHipAngle = getAngleFromThreeVNPoints(a: points[wristJoint]!, b: points[shoulderJoint]!, c: points[hipJoint]!)

        // Check arm does not fall
        if armToHipAngle < 75 || armToHipAngle > 110 {
            posteriorCapsuleStretchModel.repetitionIsGood = false
            return false
        }
        
        posteriorCapsuleStretchModel.repetitionIsGood = true
        return true
    }
}
