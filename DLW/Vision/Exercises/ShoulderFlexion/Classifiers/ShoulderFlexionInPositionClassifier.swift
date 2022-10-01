import Foundation
import Vision

struct ShoulderFlexionInPositionClassifier: Classifier {
    static func check(observation: VNHumanBodyPoseObservation) -> Bool {
        let shoulderFlexionModel: ShoulderFlexionModel = ShoulderFlexionModel.shared
        let calibrationJoints: [VNHumanBodyPoseObservation.JointName]
        let shoulderJoint: VNHumanBodyPoseObservation.JointName
        let hipJoint: VNHumanBodyPoseObservation.JointName
        let elbowJoint: VNHumanBodyPoseObservation.JointName
        let wristJoint: VNHumanBodyPoseObservation.JointName
        let oppEarJoint: VNHumanBodyPoseObservation.JointName
        
        // joints must be captured
        if shoulderFlexionModel.side == .left || (shoulderFlexionModel.currentSide == .left && shoulderFlexionModel.side == .both) {
            calibrationJoints = [
                .rightEar,
                .leftEar,
                .rightShoulder,
                .rightWrist,
                .rightElbow,
                .rightHip
            ]
            shoulderJoint = .rightShoulder
            hipJoint = .rightHip
            elbowJoint = .rightElbow
            wristJoint = .rightWrist
            oppEarJoint = .leftEar
        } else {
            calibrationJoints = [
                .leftEar,
                .rightEar,
                .leftShoulder,
                .leftWrist,
                .leftElbow,
                .leftHip
            ]
            shoulderJoint = .leftShoulder
            hipJoint = .leftHip
            elbowJoint = .leftElbow
            wristJoint = .leftWrist
            oppEarJoint = .rightEar
        }
        
        var points: [VNHumanBodyPoseObservation.JointName : VNRecognizedPoint] = [:]
        
        for joint in calibrationJoints {
            guard let point =
                    try? observation.recognizedPoint(joint), point.confidence > GlobalSettings.getDefaultConfidence() else { continue }
            points[joint] = point
        }
        
        // Check if there are sufficient points
        if points.count < calibrationJoints.count - 1 {
            return false
        }
        
        // Check that essential points are in the frame as we will accept if the opp ear is not in the frame
        if points[shoulderJoint] == nil || points[hipJoint] == nil || points[elbowJoint] == nil || points[wristJoint] == nil {
            return false
        }
        
        // Check that arms are by the user's side
        if !vnPointsAreVerticallySortedAscendingly(points: [points[wristJoint]!, points[elbowJoint]!, points[shoulderJoint]!]) {
            return false
        }
        
        // Check if the user is turned 90 degrees
        // Done by checking if the opposite ear is visible in the frame
        // Opposite ear shouldn't be in the frame if user is turned correctly
        if points[oppEarJoint] != nil {
            return false
        }
        
        return true
    }
}
