import Foundation
import Vision

struct BandedRotationRepetitionClassifier: Classifier {
    static func check(observation: VNHumanBodyPoseObservation) -> Bool {
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
            return false
        }
        
        // Check that the arms are moving in their corresponding directions
        if !vnPointsAreHorizontallySortedAscendingly(points: [points[.rightWrist]!, points[.rightElbow]!]) || !vnPointsAreHorizontallySortedAscendingly(points: [points[.leftElbow]!, points[.leftWrist]!]) {
            return false
        }
        
        // Changed from using angle to using x and y coordinates as angles were extremely unstable
        
        // Check if hands stay ~90 degrees using y coordinate of the points
        if abs(points[.leftElbow]!.y - points[.leftWrist]!.y) > 0.1 || abs(points[.rightElbow]!.y - points[.rightWrist]!.y) > 0.1 {
            return false
        }
        
        // .leftElbow is actually right elbow due to mirroring and vice versa
        let rightElbowToWristXDistance: Double = getPointsHorizontalDistance(a: points[.leftElbow]!, b: points[.leftWrist]!)
        let rightElbowToShoulderYDistance: Double = getPointsVerticalDistance(a: points[.leftElbow]!, b: points[.leftShoulder]!)
        let leftElbowToWristXDistance: Double = getPointsHorizontalDistance(a: points[.rightElbow]!, b: points[.rightWrist]!)
        let leftElbowToShoulderYDistance: Double = getPointsVerticalDistance(a: points[.rightElbow]!, b: points[.rightShoulder]!)
        
        let leftRatio = leftElbowToWristXDistance/leftElbowToShoulderYDistance
        let rightRatio = rightElbowToWristXDistance/rightElbowToShoulderYDistance
        
        // We use the ratio instead of absolute difference to account for the different distances users may be from the camera
        if leftRatio < 0.15 || rightRatio < 0.15 {
            return false
        }
        
        return true
    }
}
