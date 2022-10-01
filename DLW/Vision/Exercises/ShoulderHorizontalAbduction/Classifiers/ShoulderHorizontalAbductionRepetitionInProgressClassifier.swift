import Foundation
import Vision

struct ShoulderHorizontalAbductionRepetitionInProgressClassifier: Classifier {
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
        
        var rightXDistance:Double
        rightXDistance = abs(points[.rightShoulder]!.x - points[.rightWrist]!.x)
        
        var  leftXDistance:Double
        leftXDistance = abs(points[.leftShoulder]!.x - points[.leftWrist]!.x)
        
        // Check if arms stop (only moving within +- leeway)
        if rightXDistance >= shoulderHorizontalAbductionModel.lastRightXDistance - shoulderHorizontalAbductionModel.leeway &&
            rightXDistance <= shoulderHorizontalAbductionModel.lastRightXDistance + shoulderHorizontalAbductionModel.leeway &&
            leftXDistance >= shoulderHorizontalAbductionModel.lastLeftXDistance - shoulderHorizontalAbductionModel.leeway &&
            leftXDistance <= shoulderHorizontalAbductionModel.lastLeftXDistance + shoulderHorizontalAbductionModel.leeway {
            shoulderHorizontalAbductionModel.currentAngleFrames += 1
            return true
        } else {
            shoulderHorizontalAbductionModel.currentAngleFrames = 0
            // Check that arms are always rotating outwards
            if rightXDistance < shoulderHorizontalAbductionModel.lastRightXDistance - 0.03 {
                shoulderHorizontalAbductionModel.repetitionIsGood = false
                return false
            }
            if leftXDistance < shoulderHorizontalAbductionModel.lastLeftXDistance - 0.03 {
                shoulderHorizontalAbductionModel.repetitionIsGood = false
                return false
            }
        }
        
        // update x distance
        if rightXDistance >= shoulderHorizontalAbductionModel.lastRightXDistance - 0.01 || rightXDistance <= shoulderHorizontalAbductionModel.lastRightXDistance + 0.01 {
            shoulderHorizontalAbductionModel.lastRightXDistance = rightXDistance
        }
        if leftXDistance >= shoulderHorizontalAbductionModel.lastLeftXDistance - 0.01 || leftXDistance <= shoulderHorizontalAbductionModel.lastLeftXDistance + 0.01 {
            shoulderHorizontalAbductionModel.lastLeftXDistance = leftXDistance
        }
        
        shoulderHorizontalAbductionModel.repetitionIsGood = true
        
        return true
    }
}
