//
//  VisionHelper.swift
//  DLW
//
//  Created by Que An Tran on 1/10/22.
//

import Foundation
import AVFoundation
import UIKit
import Vision
import MLKitPoseDetection

/// Manages the Camera to be used by `MoveView`.
///
/// It extends `UIViewController` as it helps to manage the `UIView` currently being displayed.
class CameraService: UIViewController {
    
    /// The session of the camera feed being used.  The application should only ever have a single instance of this.
    static var session: AVCaptureSession?
    
    /// The output feed to be added to the preview layer.
    let videoDataOutput = AVCaptureVideoDataOutput()
    
    /// The preview layer to be displayed.
    let previewLayer = AVCaptureVideoPreviewLayer()
    
    var bodyLayers: [CAShapeLayer] = []
    
    /// A list of all landmarks to be displayed. Override this variable to display the landmarks as required.
    var drawnLandmarks: [PoseLandmarkType] { get
        { return
            [
                .leftShoulder,
                .leftElbow,
                .leftWrist,
                .leftThumb,
                .leftIndexFinger,
                .leftPinkyFinger,
                .rightShoulder,
                .rightElbow,
                .rightWrist,
                .rightThumb,
                .rightIndexFinger,
                .rightPinkyFinger,
                .leftEar,
                .leftEye,
                .leftEyeInner,
                .leftEyeOuter,
                .rightEar,
                .rightEye,
                .rightEyeInner,
                .rightEyeOuter,
                .nose,
                .mouthLeft,
                .mouthRight,
                .leftHip,
                .leftKnee,
                .leftAnkle,
                .leftHeel,
                .leftToe,
                .rightHip,
                .rightKnee,
                .rightAnkle,
                .rightHeel,
                .rightToe
            ]
        }
    }
    
    /// A list of all landmark pairs to be displayed. Override this variable to display the landmark pairs as required.
    var drawnLandmarkPairs: [[PoseLandmarkType]] { get
        { return
            [
                [.leftEar, .leftEye],
                [.leftEye, .leftEyeOuter],
                [.leftEye, .leftEyeInner],
                [.leftEye, .nose],
                [.nose, .rightEye],
                [.nose, .mouthLeft],
                [.rightEye, .rightEyeOuter],
                [.rightEye, .rightEyeInner],
                [.rightEye, .rightEar],
                [.nose, .mouthRight],
                [.leftShoulder, .rightShoulder],
                [.leftShoulder, .leftElbow],
                [.leftElbow, .leftWrist],
                [.leftWrist, .leftThumb],
                [.leftWrist, .leftIndexFinger],
                [.leftWrist, .leftPinkyFinger],
                [.rightShoulder, .rightElbow],
                [.rightElbow, .rightWrist],
                [.rightWrist, .rightThumb],
                [.rightWrist, .rightIndexFinger],
                [.rightWrist, .rightPinkyFinger],
                [.leftShoulder, .leftHip],
                [.rightShoulder, .rightHip],
                [.rightHip, .leftHip],
                [.leftHip, .leftKnee],
                [.leftKnee, .leftAnkle],
                [.leftAnkle, .leftHeel],
                [.leftHeel, .leftToe],
                [.rightHip, .rightKnee],
                [.rightKnee, .rightAnkle],
                [.rightAnkle, .rightHeel],
                [.rightHeel, .rightToe],
            ]
        }
        
    }
    
    /// A list of all joints to be displayed. Override this variable to display the joints as required.
    /// To be deprecated
    var drawnJoints: [VNHumanBodyPoseObservation.JointName] { get
        { return
            [
                .leftEar,
                .leftEye,
                .rightEar,
                .rightEye,
                .neck,
                .nose,
                .leftShoulder,
                .leftElbow,
                .leftWrist,
                .rightShoulder,
                .rightElbow,
                .rightWrist,
                .root,
                .leftHip,
                .leftKnee,
                .leftAnkle,
                .rightHip,
                .rightKnee,
                .rightAnkle
            ]
        }
    }
    
    /// A list of all joint pairs to be displayed. Override this variable to display the joint pairs as required.
    /// To be deprecated
    var drawnJointPairs: [[VNHumanBodyPoseObservation.JointName]] { get
        { return
            [
                [.leftEar, .leftEye],
                [.leftEye, .nose],
                [.nose, .rightEye],
                [.rightEye, .rightEar],
                [.leftShoulder, .rightShoulder],
                [.leftShoulder, .leftHip],
                [.rightShoulder,. rightHip],
                [.rightHip, .leftHip],
                [.leftElbow, .leftShoulder],
                [.rightElbow, .rightShoulder],
                [.rightElbow, .rightWrist],
                [.leftElbow, .leftWrist],
                [.leftHip, .leftKnee],
                [.leftKnee, .leftAnkle],
                [.rightKnee, .rightAnkle],
                [.rightKnee, .rightHip],
            ]
        }
    }
    
    /// Helper function for drawJointPairs and drawLandmarkPairs, to draw lines between specified points.
    ///
    /// - parameter layer: the layer to draw the lines on.
    /// - parameter start: the start point of the line.
    /// - parameter end: the end point of the line.
    func drawLine(onLayer layer: CALayer, fromPoint start: CGPoint, toPoint end: CGPoint) {
        let line = CAShapeLayer()
        let linePath = UIBezierPath()
        linePath.move(to: start)
        linePath.addLine(to: end)
        line.path = linePath.cgPath
        line.fillColor = nil
        line.opacity = 1.0
        line.strokeColor = UIColor.white.cgColor
        layer.addSublayer(line)
    }
    
    /// Draws all required joints in a Pose, based on the drawnJoints array.
    ///
    /// - parameter observation: the observation to draw from.
    func drawPoints(observation: VNHumanBodyPoseObservation) {
        let keys = observation.availableJointNames
        var points: [VNPoint] = []
        for joint in keys {
            if !drawnJoints.contains(joint) {
                continue
            }
            guard let point =
                    try? observation.recognizedPoint(joint), point.confidence > GlobalSettings.getDefaultConfidence() else { continue }
            points.append(point)
        }

        for point in points {
            let normalizedPoint: CGPoint = normalizePoint(point: point)
            let landmarkPath = UIBezierPath(ovalIn: CGRect(x: normalizedPoint.x, y: normalizedPoint.y, width: 10, height: 10))
            let landmarkLayer = CAShapeLayer()
            landmarkLayer.path = landmarkPath.cgPath
            landmarkLayer.fillColor = UIColor(rgb: 0x00a1a1).cgColor
            landmarkLayer.strokeColor = UIColor(rgb: 0x00a1a1).cgColor
            landmarkLayer.lineWidth = 3
            self.bodyLayers.append(landmarkLayer)
            self.previewLayer.addSublayer(landmarkLayer)
        }
    }
    
    /// Draws lines between each joint pair in a Pose, based on the drawnJointPairs array.
    ///
    /// - parameter observation: the observation to draw joint pairs for.
    func drawJointPairs(observation: VNHumanBodyPoseObservation) {
        let keys = observation.availableJointNames
        for jointPair in drawnJointPairs {
            if keys.contains(jointPair[0]) && keys.contains(jointPair[1]) {
                guard let point1 =
                        try? observation.recognizedPoint(jointPair[0]), point1.confidence > GlobalSettings.getDefaultConfidence() else { continue }
                guard let point2 =
                        try? observation.recognizedPoint(jointPair[1]), point2.confidence > GlobalSettings.getDefaultConfidence() else { continue }
                let lineLayer = CAShapeLayer()
                lineLayer.lineWidth = 3
                let normalizedPoint1 = normalizePoint(point: point1)
                let normalizedPoint2 = normalizePoint(point: point2)
                drawLine(onLayer: lineLayer, fromPoint: normalizedPoint1, toPoint: normalizedPoint2)
                self.bodyLayers.append(lineLayer)
                self.previewLayer.addSublayer(lineLayer)
            }
        }
    }
    
    /// Normalizes a VNPoint based on screen size.
    ///
    /// - parameter point: point to be normalized.
    /// - returns: CGPoint representing the normalized VNPoint.
    func normalizePoint(point: VNPoint) -> CGPoint {
        let bounds = UIScreen.main.bounds
        return CGPoint(x: point.x * bounds.width, y: bounds.height - point.y * bounds.height)
    }
    
    /// Gets the current position of the specified landmark.
    ///
    /// - parameter PoseLandmark
    /// - returns: a CGPoint representing the current position of landmark
    static func getLandmarkPosition(landmark: PoseLandmark) -> CGPoint {
        let position = landmark.position
        return CGPoint(x: position.x, y: position.y)
    }
    
    /// Normalizes a landmark based on screen size.
    ///
    /// - parameter landmark: point to be normalized.
    /// - returns: CGPoint representing the normalized point.
    func normalizeLandmark(landmark: PoseLandmark) -> CGPoint {
        let position = landmark.position
        let point = CGPoint(x: 0.75 * position.y/2, y: 0.9 * position.x/2)
        return point
    }
    
    /// Handles all states and drawings for the Pose.
    ///
    /// - parameter pose: the pose that is to be handled.
    func handlePose(pose: Pose) {
        drawLandmarks(pose: pose)
        drawLandmarkPairs(pose: pose)
        processPose(pose: pose)
    }
    
    /// Handles states for the Pose.
    ///
    /// - parameter pose: pose that is to be processed.
    /// To be overriden and implemented.
    func processPose(pose: Pose) {  }
    
    /// Draws landmarks in a pose, based on the drawnLandmarks array.
    ///
    /// - parameter pose: the pose to draw landmarks for.
    func drawLandmarks(pose: Pose) {
        let landmarks = pose.landmarks
        for landmark in landmarks {
            if (!drawnLandmarks.contains(landmark.type)) {
                continue
            }
            if landmark.inFrameLikelihood > 0.5 {
                let normalizedPosition = normalizeLandmark(landmark: landmark)
                let landmarkPath = UIBezierPath(ovalIn: CGRect(x: normalizedPosition.x, y: normalizedPosition.y, width: 10, height: 10))
                let landmarkLayer = CAShapeLayer()
                landmarkLayer.path = landmarkPath.cgPath
                landmarkLayer.fillColor = UIColor(rgb: 0x00a1a1).cgColor
                landmarkLayer.strokeColor = UIColor(rgb: 0x00a1a1).cgColor
                landmarkLayer.lineWidth = 3
                self.bodyLayers.append(landmarkLayer)
                self.previewLayer.addSublayer(landmarkLayer)
            }
        }
    }
    
    /// Draws lines between each landmark pair in a Pose, based on the drawnLandmarkPairs array.
    ///
    /// - parameter pose: the pose to draw landmark pairs for.
    func drawLandmarkPairs(pose: Pose) {
        var point1 : PoseLandmark
        var point2 : PoseLandmark
        for landmark in drawnLandmarkPairs {
            point1 = pose.landmark(ofType: landmark[0])
            point2 = pose.landmark(ofType: landmark[1])
            if point1.inFrameLikelihood > 0.95  && point2.inFrameLikelihood > 0.95 {
                let lineLayer = CAShapeLayer()
                lineLayer.lineWidth = 3
                let normalizedLandmark1 = normalizeLandmark(landmark: point1)
                let normalizedLandmark2 = normalizeLandmark(landmark: point2)
                drawLine(onLayer: lineLayer, fromPoint: normalizedLandmark1, toPoint: normalizedLandmark2)
                self.bodyLayers.append(lineLayer)
                self.previewLayer.addSublayer(lineLayer)
            }
        }
    }
    
    /// Terminates the session of the camera service.
    ///
    /// To be called as and when required to ensure that the `AVCaptureSession` is stopped when the `Move` exits.
    static func terminate() {
        session?.stopRunning()
    }
    
    /// Executes the necessary functions and checks before the camera feed is taken in,
    func start(completion: @escaping (Error?) -> ()) {
        checkPermissions(completion: completion)
    }
    
    /// Ensure that Kimia Move has sufficient permissions to utilise the phone's front facing camera.
    ///
    /// This function should only be executed when the Move is about to start to avoid unnecessarily asking for permissions e.g upon opening the application.
    /// Read more [here](https://developer.apple.com/design/human-interface-guidelines/macos/user-interaction/requesting-permission/).
    func checkPermissions(completion: @escaping (Error?) -> ()) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else { return }
                DispatchQueue.main.async {
                    self?.setupCamera(completion: completion)
                }
            }
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            setupCamera(completion: completion)
        @unknown default:
            break
        }
    }
    
    /// Sets up the camera to be used by creating the `AVCaptureSession` to be used and assigns it to the static  `session`.
    private func setupCamera(completion: @escaping (Error?) -> ()) {
        
        let session = AVCaptureSession()
        
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.session = session
                
                CameraService.session = session
                setupPreview()
            } catch {
                completion(error)
            }
        }
    }
    
    /// Sets up the preview to be displayed in the View.
    func setupPreview() {
        CameraService.session!.addOutput(self.videoDataOutput)
        CameraService.session!.startRunning()
    }
}

