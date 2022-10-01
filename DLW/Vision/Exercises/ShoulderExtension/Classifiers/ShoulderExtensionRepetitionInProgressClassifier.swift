import Foundation
import Vision

struct ShoulderExtensionRepetitionInProgressClassifier: Classifier {
    static func check(observation: VNHumanBodyPoseObservation) -> Bool {
        let shoulderExtensionModel: ShoulderExtensionModel = ShoulderExtensionModel.shared
        let calibrationJoints: [VNHumanBodyPoseObservation.JointName]
        let shoulderJoint: VNHumanBodyPoseObservation.JointName
        let hipJoint: VNHumanBodyPoseObservation.JointName
        let elbowJoint: VNHumanBodyPoseObservation.JointName
        let wristJoint: VNHumanBodyPoseObservation.JointName
        let oppEarJoint: VNHumanBodyPoseObservation.JointName

        // joints must be captured
        if shoulderExtensionModel.side == .left || (shoulderExtensionModel.currentSide == .left && shoulderExtensionModel.side == .both) {
            calibrationJoints = [
                .rightShoulder,
                .rightWrist,
                .rightElbow,
                .rightHip,
                .rightEar,
                .leftEar
            ]
            shoulderJoint = .rightShoulder
            hipJoint = .rightHip
            elbowJoint = .rightElbow
            wristJoint = .rightWrist
            oppEarJoint = .leftEar
        } else {
            calibrationJoints = [
                .leftShoulder,
                .leftWrist,
                .leftElbow,
                .leftHip,
                .leftEar,
                .rightEar
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
        
        // Check if the user is turned 90 degrees
        // Done by checking if the opposite ear is visible in the frame
        // Opposite ear shouldn't be in the frame if user is turned correctly
        if points[oppEarJoint] != nil {
            return false
        }
        
        var armToHipAngle: Double
        armToHipAngle = getAngleFromThreeVNPoints(a: points[wristJoint]!, b: points[shoulderJoint]!, c: points[hipJoint]!)

        if (points[wristJoint]!.x > points[shoulderJoint]!.x) {
            armToHipAngle *= -1;
        }
        
        if armToHipAngle >= shoulderExtensionModel.lastAngle - shoulderExtensionModel.leeway && armToHipAngle <= shoulderExtensionModel.lastAngle + shoulderExtensionModel.leeway {
            shoulderExtensionModel.currentAngleFrames += 1
            return true
        } else {
            shoulderExtensionModel.currentAngleFrames = 0
            
            // Check that arms are always going down (allow 2 degree error)
            if armToHipAngle > shoulderExtensionModel.lastAngle + 2 {
                shoulderExtensionModel.repetitionIsGood = false
                return false
            }
        }
    
        // update last angle
        if armToHipAngle >= shoulderExtensionModel.lastAngle - 2 || armToHipAngle <= shoulderExtensionModel.lastAngle + 2 {
            shoulderExtensionModel.lastAngle = armToHipAngle
        }
    
        shoulderExtensionModel.repetitionIsGood = true
        return true
    }
}
