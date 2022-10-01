import Foundation
import Vision

struct BandedRotationRepetitionInProgressClassifier: Classifier {
    static func check(observation: VNHumanBodyPoseObservation) -> Bool {
        let bandedRotationModel: BandedRotationModel = BandedRotationModel.shared
        let calibrationJoints: [VNHumanBodyPoseObservation.JointName]
        
        // joints must be captured
        calibrationJoints = [
            .rightWrist,
            .rightElbow,
            .rightShoulder,
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
            bandedRotationModel.currentAngleFrames = 0
            bandedRotationModel.repetitionIsGood = false
            return false
        }
        
        // Check that the arms are moving in their corresponding directions
        if !vnPointsAreHorizontallySortedAscendingly(points: [points[.rightWrist]!, points[.rightElbow]!]) || !vnPointsAreHorizontallySortedAscendingly(points: [points[.leftElbow]!, points[.leftWrist]!]) {
            bandedRotationModel.currentAngleFrames = 0
            bandedRotationModel.repetitionIsGood = false
            return false
        }
        
        // .leftElbow is actually right elbow due to mirroring and vice versa
        let rightElbowToWristXDistance: Double = getPointsHorizontalDistance(a: points[.leftElbow]!, b: points[.leftWrist]!)
        let rightElbowToShoulderYDistance: Double = getPointsVerticalDistance(a: points[.leftElbow]!, b: points[.leftShoulder]!)
        let leftElbowToWristXDistance: Double = getPointsHorizontalDistance(a: points[.rightElbow]!, b: points[.rightWrist]!)
        let leftElbowToShoulderYDistance: Double = getPointsVerticalDistance(a: points[.rightElbow]!, b: points[.rightShoulder]!)
        
        let leftRatio = leftElbowToWristXDistance/leftElbowToShoulderYDistance
        let rightRatio = rightElbowToWristXDistance/rightElbowToShoulderYDistance
        
        // Checks if the current ratio on both arms are within the leeway buffer from the prev ratio
        if (leftRatio >= bandedRotationModel.lastLeftRatio - bandedRotationModel.leeway && leftRatio <= bandedRotationModel.lastLeftRatio + bandedRotationModel.leeway) && (rightRatio >= bandedRotationModel.lastRightRatio - bandedRotationModel.leeway && rightRatio <= bandedRotationModel.lastRightRatio + bandedRotationModel.leeway) {
            bandedRotationModel.currentAngleFrames += 1
            bandedRotationModel.repetitionIsGood = true
            return true
        } else {
            bandedRotationModel.currentAngleFrames = 0
            // Check that the ratio is increasing
            if leftRatio < bandedRotationModel.lastLeftRatio - 0.2 || rightRatio < bandedRotationModel.lastRightRatio - 0.2 {
                bandedRotationModel.repetitionIsGood = false
                return false
            }
        }
        
        // Update the last angle only when its within this buffer
        if leftRatio >= bandedRotationModel.lastLeftRatio - 0.05 || leftRatio <= bandedRotationModel.lastLeftRatio + 0.05 {
            bandedRotationModel.lastLeftRatio = leftRatio
        }
        if rightRatio >= bandedRotationModel.lastRightRatio - 0.05 || rightRatio <= bandedRotationModel.lastRightRatio + 0.05 {
            bandedRotationModel.lastRightRatio = rightRatio
        }
        
        bandedRotationModel.repetitionIsGood = true
        return true
    }
}
