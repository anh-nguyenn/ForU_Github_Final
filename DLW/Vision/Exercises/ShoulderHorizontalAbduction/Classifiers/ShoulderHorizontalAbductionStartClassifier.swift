import Foundation
import Vision

struct ShoulderHorizontalAbductionStartClassifier: Classifier {
    static func check(observation: VNHumanBodyPoseObservation) -> Bool {
        var points: [VNPoint] = []
        let shoulderHorizontalAbductionModel: ShoulderHorizontalAbductionModel = ShoulderHorizontalAbductionModel.shared

        // Calibration of the image is basically asking them to move backwards sufficiently
        let calibrationJoints: [VNHumanBodyPoseObservation.JointName]
        
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
        
        for joint in calibrationJoints {
            guard let point =
                    try? observation.recognizedPoint(joint), point.confidence > GlobalSettings.getDefaultConfidence() else { continue }
            points.append(point)
        }
        
        // Check if there are sufficient points
        if points.count < calibrationJoints.count {
            return false
        }
                
        // Waiting for audio
        if shoulderHorizontalAbductionModel.calibrationFrames > 100 {
            shoulderHorizontalAbductionModel.calibrationFrames = 0
            return true
        } else {
            shoulderHorizontalAbductionModel.calibrationFrames += 1
            return false
        }
    }
    
}
