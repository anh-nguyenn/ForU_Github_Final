import Foundation
import Vision
import Network

struct BandedRotationInPositionClassifier: Classifier {
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
        
        let leftWristElbowDistance: Double = getPointsVerticalDistance(a: points[.rightWrist]!, b: points[.rightElbow]!)
        let leftWristShoulderDistance: Double = getPointsVerticalDistance(a: points[.rightWrist]!, b: points[.rightShoulder]!)
        let rightWristElbowDistance: Double = getPointsVerticalDistance(a: points[.leftWrist]!, b: points[.leftElbow]!)
        let rightWristShoulderDistance: Double = getPointsVerticalDistance(a: points[.leftWrist]!, b: points[.leftShoulder]!)
        
        // Checks whether the arms are facing straight
        // When arms are facing straight, x coordinate of wrist and elbow will be quite similar
        // Did not use angles as they are unreliable
        if abs(points[.leftShoulder]!.x - points[.leftWrist]!.x) > 0.1 || abs(points[.rightShoulder]!.x - points[.rightWrist]!.x) > 0.1 {
            return false
        }

        // Checks whether the arms are bent 90 degrees
        // Ratio of wrist elbow distance and wrist shoulder distance should be close to 0
        if (leftWristElbowDistance / leftWristShoulderDistance) > 0.2 || (rightWristElbowDistance / rightWristShoulderDistance) > 0.2{
            return false
        }
        
        return true
    }
}
