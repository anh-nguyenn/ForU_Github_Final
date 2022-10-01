import Foundation
import Vision

struct BandedRotationStartClassifier: Classifier {
    static func check(observation: VNHumanBodyPoseObservation) -> Bool {
        var points: [VNPoint] = []
        
        // Calibration of the image is basically asking them to move backwards sufficiently
        let bandedRotationModel: BandedRotationModel = BandedRotationModel.shared
        let calibrationJoints: [VNHumanBodyPoseObservation.JointName]
        
        // joints must be captured
        calibrationJoints = [
            .rightShoulder,
            .rightElbow,
            .rightWrist,
            .leftShoulder,
            .leftWrist,
            .leftElbow
        ]
        
        for joint in calibrationJoints {
            guard let point =
                    try? observation.recognizedPoint(joint), point.confidence > GlobalSettings.getDefaultConfidence() else { continue }
            points.append(point)
        }
        
        if points.count < calibrationJoints.count {
            return false
        }
        
        if bandedRotationModel.calibrationFrames > 80 {
            bandedRotationModel.calibrationFrames = 0
            return true
        } else {
            bandedRotationModel.calibrationFrames += 1
            return false
        }
    }
    
}
