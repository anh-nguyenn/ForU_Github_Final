import AVFoundation
import Vision
import UIKit
import SwiftUI
import GameplayKit
import GameKit

class ShoulderAbductionViewController: CameraService {
    private var initial: Bool = true
    private var shoulderAbductionModel: ShoulderAbductionModel = ShoulderAbductionModel.shared
    
    override var drawnJoints: [VNHumanBodyPoseObservation.JointName] {
        get {
            if shoulderAbductionModel.side == .left || (shoulderAbductionModel.currentSide == .left && shoulderAbductionModel.side == .both) {
                return [
                    .leftShoulder,
                    .rightShoulder,
                    .rightWrist,
                    .rightElbow,
                    .rightHip
                ]
            } else {
                return [
                    .leftShoulder,
                    .rightShoulder,
                    .leftWrist,
                    .leftElbow,
                    .leftHip
                ]
            }
        }
    }
    
    override var drawnJointPairs: [[VNHumanBodyPoseObservation.JointName]] {
        get {
            if shoulderAbductionModel.side == .left || (shoulderAbductionModel.currentSide == .left && shoulderAbductionModel.side == .both) {
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


extension ShoulderAbductionViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
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
        if shoulderAbductionModel.currentState == nil {
            shoulderAbductionModel.enter(ShoulderAbductionModel.InitialState.self)
            return
        }
        
        let state = shoulderAbductionModel.currentState
        
        switch state {
        case state as ShoulderAbductionModel.InitialState:
            initialProcessObservation(observation: observation)
            break
        case state as ShoulderAbductionModel.CalibrationState:
            calibrationProcessObservation(observation: observation)
            break
        case state as ShoulderAbductionModel.StartState:
            startProcessObservation(observation: observation)
            break
        case state as ShoulderAbductionModel.RepetitionState:
            repetitionProcessObservation(observation: observation)
            break
        case state as ShoulderAbductionModel.RepetitionInitialState:
            repetitionInitialProcessObservation(observation: observation)
            break
        case state as ShoulderAbductionModel.RepetitionInProgressState:
            repetitionInProgressProcessObservation(observation: observation)
            break
        case state as ShoulderAbductionModel.RepetitionCompletedState:
            repetitionCompletedProcessObservation(observation: observation)
            break
        default:
            break
        }
    }
    
    private func initialProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.shoulderAbductionModel
        
        if model.instructed {
            model.enter(ShoulderAbductionModel.CalibrationState.self)
        }
    }
    
    private func calibrationProcessObservation(observation: VNHumanBodyPoseObservation) {
        let result = ShoulderAbductionStartClassifier.check(observation: observation)
        
        if result {
            self.shoulderAbductionModel.enter(ShoulderAbductionModel.StartState.self)
        }
    }
    
    private func startProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.shoulderAbductionModel
        let result = ShoulderAbductionInPositionClassifier.check(observation: observation)
        
        if !result {
            return
        }
        
        if model.firstRepetition {
            if model.enter(ShoulderAbductionModel.InPositionState.self){
                    Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                        ShoulderAbductionModel.sharedTimers.append(timer)
                        if model.startTimeLeft == 0 {
                            if model.enter(ShoulderAbductionModel.RepetitionState.self) {
                                model.startTimeLeft = ShoulderAbductionModel.startTime
                                timer.invalidate()
                            }
                        } else {
                            model.startTimeLeft -= 1
                        }
                    }
                }
            } else {
                model.enter(ShoulderAbductionModel.RepetitionInitialState.self)
            }
    }
    
    private func repetitionProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.shoulderAbductionModel
        
        if model.firstRepetition {
            model.enter(ShoulderAbductionModel.RepetitionInitialState.self)
            return
        }
        
        if model.remainingSets <= 0 {
            if model.side == .both && model.currentSide == .right {
                model.updateToLeftSide()
                model.remainingSets = ShoulderAbductionModel.sets
                model.remainingRepetitions = ShoulderAbductionModel.repetitions
                model.enter(ShoulderAbductionModel.StartState.self)
                return
            }
            model.transitionTimer = ShoulderAbductionModel.transitionTime
            model.exerciseCompleted = true
            model.transitionTimerIsActive = true
            model.enter(ShoulderAbductionModel.ExerciseEndState.self)
            return
        } else {
            model.enter(ShoulderAbductionModel.StartState.self)
        }
    }
    
    private func repetitionInitialProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.shoulderAbductionModel
        
        // Timer
        if (!model.isActivated) {
            model.isActivated = true
            repetitionTimer()
        }
        
        let result = ShoulderAbductionRepetitionClassifier.check(observation: observation)
        
        if result {
            model.enter(ShoulderAbductionModel.RepetitionInProgressState.self)
        }
    }

    private func repetitionInProgressProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.shoulderAbductionModel
        
        ShoulderAbductionRepetitionInProgressClassifier.check(observation: observation)
        
        if model.currentAngleFrames > 20 {
            model.leeway = 3
        } else {
            model.leeway = 1
        }
        if model.currentAngleFrames == 50 {
            model.currentAngleFrames = 0
            model.remainingRepetitions -= 1
            model.completedReps += 1
            if model.remainingRepetitions <= 0 {
                model.setCompleted = true
            }
            model.bufferTime = model.setCompleted ? model.setCompletedInterval : model.bufferInterval
            model.enter(ShoulderAbductionModel.RepetitionCompletedState.self)
        }
    }
    
    private func repetitionCompletedProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.shoulderAbductionModel
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { timer in
            if model.currentState!.description ==
                ShoulderAbductionModel.RepetitionCompletedState().description {
                if model.bufferTime <= 0 {
                    if model.setCompleted {
                        model.remainingSets -= 1
                        model.completedSets += 1
                        model.remainingRepetitions = ShoulderAbductionModel.repetitions
                        model.setCompleted = false
                    }
                    if model.firstRepetition {
                        model.firstRepetition = false
                    }
                    
                    if model.currentSide == .left && model.firstLeftRepetition {
                        model.firstLeftRepetition = false
                    }
                    model.enter(ShoulderAbductionModel.RepetitionState.self)
                    
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
        let model = self.shoulderAbductionModel
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if model.currentState!.description != ShoulderAbductionModel.RepetitionInProgressState().description &&
                model.currentState!.description != ShoulderAbductionModel.RepetitionState().description &&
                model.currentState!.description != ShoulderAbductionModel.RepetitionInitialState().description {
                model.repetitionDurationLeft = ShoulderAbductionModel.repetitionDuration
                timer.invalidate()
                return
            }
            
            // exerciseCompleted flag is set when either all reps and sets are completed, the user skips to the next exercise or the user exits back to the homepage.
            // If we don't check this, timer will continue to run even as the user moves on to somewhere else
            if model.exerciseCompleted {
                model.repetitionDurationLeft = ShoulderAbductionModel.repetitionDuration
                model.isActivated = false
                timer.invalidate()
                return
            }
            
            if model.repetitionDurationLeft <= 0 {
                if !model.repetitionIsGood {
                    model.isGiveUp = true
                }
                model.repetitionDurationLeft = ShoulderAbductionModel.repetitionDuration
                model.currentAngleFrames = 0
                model.remainingRepetitions -= 1
                model.completedReps += 1
                if model.remainingRepetitions <= 0 {
                    model.setCompleted = true
                }
                model.bufferTime = model.setCompleted ? model.setCompletedInterval : model.bufferInterval
                model.enter(ShoulderAbductionModel.RepetitionCompletedState.self)
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
