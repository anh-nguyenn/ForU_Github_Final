import Foundation
import Vision

struct ShoulderHorizontalAbductionInPositionClassifier: Classifier {
    static func check(observation: VNHumanBodyPoseObservation) -> Bool {
        let shoulderHorizontalAbductionModel: ShoulderHorizontalAbductionModel = ShoulderHorizontalAbductionModel.shared
        let calibrationJoints: [VNHumanBodyPoseObservation.JointName]
        let rightElbowJoint: VNHumanBodyPoseObservation.JointName
        let rightShoulderJoint: VNHumanBodyPoseObservation.JointName
        let rightHipJoint: VNHumanBodyPoseObservation.JointName
        let leftShoulderJoint: VNHumanBodyPoseObservation.JointName
        let leftElbowJoint: VNHumanBodyPoseObservation.JointName
        let leftHipJoint:VNHumanBodyPoseObservation.JointName

        // joints must be captured
        calibrationJoints = [
            .rightHip,
            .rightShoulder,
            .rightElbow,
            .rightWrist,
            .leftHip,
            .leftShoulder,
            .leftElbow,
            .leftWrist
        ]
        
        rightElbowJoint = .rightElbow
        rightShoulderJoint = .rightShoulder
        rightHipJoint = .rightHip
        leftShoulderJoint = .leftShoulder
        leftElbowJoint = .leftElbow
        leftHipJoint = .leftHip
        
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
        
        // Checks whether the arms are facing straight by angles
        let rightArmAngle: Double = getAngleFromThreeVNPoints(a: points[rightElbowJoint]!, b: points[rightShoulderJoint]!, c: points[rightHipJoint]!)
        
        let leftArmAngle: Double = getAngleFromThreeVNPoints(a: points[leftElbowJoint]!, b: points[leftShoulderJoint]!, c: points[leftHipJoint]!)
        
        if rightArmAngle < 50 || leftArmAngle < 50 || rightArmAngle > 130 || rightArmAngle > 130{
            return false
        }
        
        // Checks whether the arms are facing straight by x-coordinate
        var rightXDistace:Double
        rightXDistace = abs(points[.rightShoulder]!.x - points[.rightWrist]!.x)
        
        var leftXDistance:Double
        leftXDistance = abs(points[.leftShoulder]!.x - points[.leftWrist]!.x)
        
        if rightXDistace > 0.1 || leftXDistance > 0.1 {
            return false
        }
        
        // Save the X distance to help check in RepetitionClassifier
        shoulderHorizontalAbductionModel.lastRightXDistance = rightXDistace
        shoulderHorizontalAbductionModel.lastLeftXDistance = leftXDistance
        
        // Waiting for audio
        if shoulderHorizontalAbductionModel.calibrationFrames > 20 {
            shoulderHorizontalAbductionModel.calibrationFrames = 0
            return true
        } else {
            shoulderHorizontalAbductionModel.calibrationFrames += 1
            return false
        }
    }
}
