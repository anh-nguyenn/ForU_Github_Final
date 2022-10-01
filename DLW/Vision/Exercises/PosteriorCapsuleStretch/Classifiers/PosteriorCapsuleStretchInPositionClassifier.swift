import Vision

struct PosteriorCapsuleStretchInPositionClassifier: Classifier {
    static func check(observation: VNHumanBodyPoseObservation) -> Bool {
        let posteriorCapsuleStretchModel: PosteriorCapsuleStretchModel = PosteriorCapsuleStretchModel.shared
        let joints: [VNHumanBodyPoseObservation.JointName]
        
        let shoulderJoint: VNHumanBodyPoseObservation.JointName
        let hipJoint: VNHumanBodyPoseObservation.JointName
        let elbowJoint: VNHumanBodyPoseObservation.JointName
        let wristJoint: VNHumanBodyPoseObservation.JointName
        let oppElbowJoint: VNHumanBodyPoseObservation.JointName
        let oppWristJoint: VNHumanBodyPoseObservation.JointName
        
        // joints must be captured
        if posteriorCapsuleStretchModel.side == .left || (posteriorCapsuleStretchModel.currentSide == .left && posteriorCapsuleStretchModel.side == .both) {
            joints = [
                .leftShoulder,
                .leftElbow,
                .leftWrist,
                .leftHip,
                .rightElbow,
                .rightWrist
            ]
            shoulderJoint = .leftShoulder
            hipJoint = .leftHip
            elbowJoint = .leftElbow
            wristJoint = .leftWrist
            oppElbowJoint = .rightElbow
            oppWristJoint = .rightWrist
        } else {
            joints = [
                .rightShoulder,
                .rightElbow,
                .rightWrist,
                .rightHip,
                .leftElbow,
                .leftWrist
            ]
            shoulderJoint = .rightShoulder
            hipJoint = .rightHip
            elbowJoint = .rightElbow
            wristJoint = .rightWrist
            oppElbowJoint = .leftElbow
            oppWristJoint = .leftWrist
        }
        
        var points: [VNHumanBodyPoseObservation.JointName : VNRecognizedPoint] = [:]
        
        for joint in joints {
            guard let point =
                    try? observation.recognizedPoint(joint), point.confidence > GlobalSettings.getDefaultConfidence() else { continue }
            points[joint] = point
        }
                
        // Check if there are sufficient points
        if points.count < joints.count {
            return false
        }
        
        // Essential points are missing
        if points[shoulderJoint] == nil || points[elbowJoint] == nil || points[wristJoint] == nil || points[hipJoint] == nil {
            return false
        }
        
        var armToHipAngle: Double
        armToHipAngle = getAngleFromThreeVNPoints(a: points[wristJoint]!, b: points[shoulderJoint]!, c: points[hipJoint]!)
        
        // Check for arm direction
        if posteriorCapsuleStretchModel.side == .left || (posteriorCapsuleStretchModel.currentSide == .left && posteriorCapsuleStretchModel.side == .both) {
            if !vnPointsAreHorizontallySortedAscendingly(points: [points[shoulderJoint]!, points[elbowJoint]!, points[wristJoint]!]) {
                return false
            }
        } else {
            if !vnPointsAreHorizontallySortedAscendingly(points: [points[wristJoint]!, points[elbowJoint]!, points[shoulderJoint]!]) {
                return false
            }
        }
        
        // Check if the other arm is bending up to pull the affected arm
        if !vnPointsAreVerticallySortedAscendingly(points: [points[oppElbowJoint]!, points[oppWristJoint]!]) {
            return false
        }
        
        // Check angle of arms to hip
        if armToHipAngle < 60 || armToHipAngle > 110 {
            return false
        }
        
        posteriorCapsuleStretchModel.lastAngle = armToHipAngle
        return true
    }
}
