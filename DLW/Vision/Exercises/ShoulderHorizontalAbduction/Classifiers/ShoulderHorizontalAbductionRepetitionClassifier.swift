import Foundation
import Vision

struct ShoulderHorizontalAbductionRepetitionClassifier: Classifier {
    static func check(observation: VNHumanBodyPoseObservation) -> Bool {
        let shoulderHorizontalAbductionModel: ShoulderHorizontalAbductionModel = ShoulderHorizontalAbductionModel.shared
        let calibrationJoints: [VNHumanBodyPoseObservation.JointName]
        
        // joints must be captured
        calibrationJoints = [
            .rightShoulder,
            .rightElbow,
            .rightWrist,
            .leftShoulder,
            .leftElbow,
            .leftWrist
        ]
        
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
        
        var rightXDistace:Double
        rightXDistace = abs(points[.rightShoulder]!.x - points[.rightWrist]!.x)
        
        var  leftXDistance:Double
        leftXDistance = abs(points[.leftShoulder]!.x - points[.leftWrist]!.x)
        
        // Check that arms are rotating outwards
        if rightXDistace < shoulderHorizontalAbductionModel.lastRightXDistance + 0.15 || leftXDistance < shoulderHorizontalAbductionModel.lastLeftXDistance + 0.15 {
            return false
        }
        
        // Save the X distance to help check in RepetitionInProgrssClassifier
        shoulderHorizontalAbductionModel.lastRightXDistance = rightXDistace
        shoulderHorizontalAbductionModel.lastLeftXDistance = leftXDistance
        
        return true
    }
}
