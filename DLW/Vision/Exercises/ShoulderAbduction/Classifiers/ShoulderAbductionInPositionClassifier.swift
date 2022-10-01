import Foundation
import Vision

struct ShoulderAbductionInPositionClassifier: Classifier {
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
        
        // Check if the arms are facing downwards
        if !vnPointsAreVerticallySortedAscendingly(points: [points[wristJoint]!, points[elbowJoint]!, points[shoulderJoint]!]) {
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
        
        // Check angle of arms to hip when starting
        if armToHipAngle > 30 {
            return false
        }
        
        // Save the starting angle to help check in RepetitionClassifier
        shoulderAbductionModel.lastAngle = armToHipAngle
        
        // Waiting for audio
        if shoulderAbductionModel.calibrationFrames > 20 {
            shoulderAbductionModel.calibrationFrames = 0
            return true
        } else {
            shoulderAbductionModel.calibrationFrames += 1
            return false
        }        
    }
}
