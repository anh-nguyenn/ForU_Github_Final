import AVFoundation
import Vision
import UIKit
import SwiftUI
import GameplayKit
import GameKit

class ShoulderFlexionViewController: CameraService {
    private var initial: Bool = true
    private var shoulderFlexionModel: ShoulderFlexionModel = ShoulderFlexionModel.shared
    
    override var drawnJoints: [VNHumanBodyPoseObservation.JointName] {
        get {
            if shoulderFlexionModel.side == .left || (shoulderFlexionModel.currentSide == .left && shoulderFlexionModel.side == .both) {
                return [
                    .rightShoulder,
                    .rightWrist,
                    .rightElbow,
                    .rightHip
                ]
            } else {
                return [
                    .leftShoulder,
                    .leftWrist,
                    .leftElbow,
                    .leftHip
                ]
            }
        }
    }
    
    override var drawnJointPairs: [[VNHumanBodyPoseObservation.JointName]] {
        get {
            if shoulderFlexionModel.side == .left || (shoulderFlexionModel.currentSide == .left && shoulderFlexionModel.side == .both) {
                return [
                    [.rightHip, .rightShoulder],
                    [.rightShoulder, .rightElbow],
                    [.rightElbow, .rightWrist]
                ]
            } else {
                return [
                    [.leftHip, .leftShoulder],
                    [.leftShoulder, .leftElbow],
                    [.leftElbow, .leftWrist]
                ]
            }
        }
    }
    
    override func setupPreview() {
        self.previewLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(self.previewLayer)
        self.previewLayer.frame = self.view.frame

        self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]

        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "Buffer Processing Queue"))

        let videoConnection = self.videoDataOutput.connection(with: .video)
        videoConnection?.videoOrientation = .portrait
        super.setupPreview()
    }
}


extension ShoulderFlexionViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
          return
        }

        let poseDetectionRequest = VNDetectHumanBodyPoseRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                while (!self.bodyLayers.isEmpty) {
                    let drawing = self.bodyLayers.remove(at: 0)
                    drawing.removeFromSuperlayer()
                }
                if let observations = request.results as? [VNHumanBodyPoseObservation] {
                    self.handleBodyDetectionObservations(observations: observations)
                } else {
                    return
                }
            }
        })
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, orientation: .leftMirrored, options: [:])

        do {
            try imageRequestHandler.perform([poseDetectionRequest])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func handleBodyDetectionObservations(observations: [VNHumanBodyPoseObservation]) {
        for observation in observations {
            handlePoseObservation(observation: observation)
        }
    }
    
    private func handlePoseObservation(observation: VNHumanBodyPoseObservation) {
        drawObservation(observation: observation)
        processObservation(observation: observation)
    }
    
    private func processObservation(observation: VNHumanBodyPoseObservation) {
        if shoulderFlexionModel.currentState == nil {
            shoulderFlexionModel.enter(ShoulderFlexionModel.InitialState.self)
            return
        }
        
        let state = shoulderFlexionModel.currentState
        
        switch state {
        case state as ShoulderFlexionModel.InitialState:
            initialProcessObservation(observation: observation)
            break
        case state as ShoulderFlexionModel.CalibrationState:
            calibrationProcessObservation(observation: observation)
            break
        case state as ShoulderFlexionModel.StartState:
            startProcessObservation(observation: observation)
            break
        case state as ShoulderFlexionModel.RepetitionState:
            repetitionProcessObservation(observation: observation)
            break
        case state as ShoulderFlexionModel.RepetitionInitialState:
            repetitionInitialProcessObservation(observation: observation)
            break
        case state as ShoulderFlexionModel.RepetitionInProgressState:
            repetitionInProgressProcessObservation(observation: observation)
            break
        case state as ShoulderFlexionModel.RepetitionCompletedState:
            repetitionCompletedProcessObservation(observation: observation)
            break
        default:
            break
        }
    }
    
    private func initialProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.shoulderFlexionModel
        
        if model.instructed {
            model.enter(ShoulderFlexionModel.CalibrationState.self)
        }
    }
    
    private func calibrationProcessObservation(observation: VNHumanBodyPoseObservation) {
        let result = ShoulderFlexionStartClassifier.check(observation: observation)
        
        if result {
            self.shoulderFlexionModel.enter(ShoulderFlexionModel.StartState.self)
        }
    }
    
    private func startProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.shoulderFlexionModel
        
        let result = ShoulderFlexionInPositionClassifier.check(observation: observation)
        
        if !result {
            return
        }
        
        if model.firstRepetition {
            if model.enter(ShoulderFlexionModel.InPositionState.self){
                    Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                        ShoulderFlexionModel.sharedTimers.append(timer)
                        if model.startTimeLeft == 0 {
                            if model.enter(ShoulderFlexionModel.RepetitionState.self) {
                                model.startTimeLeft = ShoulderFlexionModel.startTime
                                timer.invalidate()
                            }
                        } else {
                            model.startTimeLeft -= 1
                        }
                    }
                }
            } else {
                model.enter(ShoulderFlexionModel.RepetitionInitialState.self)
            }
    }
    
    private func repetitionProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.shoulderFlexionModel
        
        if model.firstRepetition {
            model.enter(ShoulderFlexionModel.RepetitionInitialState.self)
            return
        }
        
        if model.remainingSets <= 0 {
            if model.side == .both && model.currentSide == .right {
                model.updateToLeftSide()
                model.remainingSets = ShoulderFlexionModel.sets
                model.remainingRepetitions = ShoulderFlexionModel.repetitions
                model.enter(ShoulderFlexionModel.StartState.self)
                return
            }
            model.transitionTimer = ShoulderFlexionModel.transitionTime
            model.exerciseCompleted = true
            model.transitionTimerIsActive = true
            model.enter(ShoulderFlexionModel.ExerciseEndState.self)
            return
        } else {
            model.enter(ShoulderFlexionModel.StartState.self)
        }
    }
    
    private func repetitionInitialProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.shoulderFlexionModel
        
        // Timer
        if (!model.isActivated) {
            model.isActivated = true
            repetitionTimer()
        }
        
        let result = ShoulderFlexionRepetitionClassifier.check(observation: observation)
        
        if result {
            model.enter(ShoulderFlexionModel.RepetitionInProgressState.self)
        }
    }

    private func repetitionInProgressProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.shoulderFlexionModel
        
        ShoulderFlexionRepetitionInProgressClassifier.check(observation: observation)
        
        if model.currentAngleFrames > 40 {
            model.leeway = 3
        } else {
            model.leeway = 1.5
        }
        if model.currentAngleFrames == 60 {
            model.currentAngleFrames = 0
            model.lastAngle = 0
            model.remainingRepetitions -= 1
            model.completedReps += 1
            if model.remainingRepetitions <= 0 {
                model.setCompleted = true
            }
            model.bufferTime = model.setCompleted ? model.setCompletedInterval : model.bufferInterval
            model.enter(ShoulderFlexionModel.RepetitionCompletedState.self)
        }
    }
    
    private func repetitionCompletedProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.shoulderFlexionModel
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { timer in
            if model.currentState!.description ==
                ShoulderFlexionModel.RepetitionCompletedState().description {
                if model.bufferTime <= 0 {
                    if model.setCompleted {
                        model.remainingSets -= 1
                        model.completedSets += 1
                        model.remainingRepetitions = ShoulderFlexionModel.repetitions
                        model.setCompleted = false
                    }
                    if model.firstRepetition {
                        model.firstRepetition = false
                    }
                    
                    if model.currentSide == .left && model.firstLeftRepetition {
                        model.firstLeftRepetition = false
                    }
                    model.enter(ShoulderFlexionModel.RepetitionState.self)
                    
                    // Timer
                    model.isActivated = false
                    model.isGiveUp = false
                    
                    timer.invalidate()
                } else {
                    model.bufferTime -= 0.1
                }
            }
        }
    }
    
    // Timer
    func repetitionTimer() {
        let model = self.shoulderFlexionModel
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if model.currentState!.description != ShoulderFlexionModel.RepetitionInProgressState().description &&
                model.currentState!.description != ShoulderFlexionModel.RepetitionState().description &&
                model.currentState!.description != ShoulderFlexionModel.RepetitionInitialState().description {
                model.repetitionDurationLeft = ShoulderFlexionModel.repetitionDuration
                timer.invalidate()
                return
            }
            
            // exerciseCompleted flag is set when either all reps and sets are completed, the user skips to the next exercise or the user exits back to the homepage.
            // If we don't check this, timer will continue to run even as the user moves on to somewhere else
            if model.exerciseCompleted {
                model.repetitionDurationLeft = ShoulderFlexionModel.repetitionDuration
                model.isActivated = false
                timer.invalidate()
                return
            }
            if model.repetitionDurationLeft <= 0 {
                if !model.repetitionIsGood {
                    model.isGiveUp = true
                }
                model.repetitionDurationLeft = ShoulderFlexionModel.repetitionDuration
                model.currentAngleFrames = 0
                model.lastAngle = 0
                model.remainingRepetitions -= 1
                model.completedReps += 1
                if model.remainingRepetitions <= 0 {
                    model.setCompleted = true
                }
                model.bufferTime = model.setCompleted ? model.setCompletedInterval : model.bufferInterval
                model.enter(ShoulderFlexionModel.RepetitionCompletedState.self)
                timer.invalidate()
                return
            } else {
                model.repetitionDurationLeft -= 0.1
            }
        }
    }
    
    func drawObservation(observation: VNHumanBodyPoseObservation) {
        drawPoints(observation: observation)
        drawJointPairs(observation: observation)
    }
    
    func end(_with settings: AVCapturePhotoSettings = AVCapturePhotoSettings()) {
//        session?.stopRunning()
        // uncomment to exit
//        output.capturePhoto(with: settings, delegate: delegate!)
    }
}
