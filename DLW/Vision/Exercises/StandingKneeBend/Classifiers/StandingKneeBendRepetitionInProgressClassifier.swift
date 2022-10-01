import Foundation
import Vision

struct StandingKneeBendRepetitionInProgressClassifier: Classifier {
    static func check(observation: VNHumanBodyPoseObservation) -> Bool {
        let standingKneeBendModel: StandingKneeBendModel = StandingKneeBendModel.shared
        let calibrationJoints: [VNHumanBodyPoseObservation.JointName]
        let hipJoint: VNHumanBodyPoseObservation.JointName
        let kneeJoint: VNHumanBodyPoseObservation.JointName
        let ankleJoint: VNHumanBodyPoseObservation.JointName
        
        // joints must be captured
        if standingKneeBendModel.side == .left || (standingKneeBendModel.currentSide == .left && standingKneeBendModel.side == .both) {
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
            standingKneeBendModel.repetitionIsGood = false
            standingKneeBendModel.badFrames += 1
            return false
        }
        
        // Make sure leg angle is still held around 90 degrees
        let legAngle: Double = getAngleFromThreeVNPoints(a: points[hipJoint]!, b: points[kneeJoint]!, c: points[ankleJoint]!)
        
        if legAngle > 100 {
            standingKneeBendModel.repetitionIsGood = false
            standingKneeBendModel.badFrames += 1
            return false
        }
        
        // Check if the legs are facing in the right direction
        if standingKneeBendModel.side == .left || (standingKneeBendModel.currentSide == .left && standingKneeBendModel.side == .both) {
            if !vnPointsAreHorizontallySortedAscendingly(points: [points[ankleJoint]!, points[kneeJoint]!]) {
                standingKneeBendModel.repetitionIsGood = false
                standingKneeBendModel.badFrames += 1
                return false
            }
        } else {
            if !vnPointsAreHorizontallySortedAscendingly(points: [points[kneeJoint]!, points[ankleJoint]!]) {
                standingKneeBendModel.repetitionIsGood = false
                standingKneeBendModel.badFrames += 1
                return false
            }
        }

        standingKneeBendModel.repetitionIsGood = true
        standingKneeBendModel.goodFrames += 1
        return true
    }
}


