import AVFoundation
import Vision
import UIKit
import SwiftUI
import GameplayKit
import GameKit

class InternalRotationWithResistanceBandViewController: CameraService {
    private var initial: Bool = true
    private var internalRotationWithResistanceBandModel: InternalRotationWithResistanceBandModel = InternalRotationWithResistanceBandModel.shared
    
    override var drawnJoints: [VNHumanBodyPoseObservation.JointName] {
        get {
            if internalRotationWithResistanceBandModel.side == .left || (internalRotationWithResistanceBandModel.currentSide == .left && internalRotationWithResistanceBandModel.side == .both) {
                return [
                    .rightShoulder,
                    .rightWrist,
                    .rightElbow,
                ]
            } else {
                return [
                    .leftShoulder,
                    .leftWrist,
                    .leftElbow,
                ]
            }
        }
    }
    
    override var drawnJointPairs: [[VNHumanBodyPoseObservation.JointName]] {
        get {
            if internalRotationWithResistanceBandModel.side == .left || (internalRotationWithResistanceBandModel.currentSide == .left && internalRotationWithResistanceBandModel.side == .both) {
                return [
                    [.rightShoulder, .rightElbow],
                    [.rightElbow, .rightWrist]
                ]
            } else {
                return [
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


extension InternalRotationWithResistanceBandViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
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
        if internalRotationWithResistanceBandModel.currentState == nil {
            internalRotationWithResistanceBandModel.enter(InternalRotationWithResistanceBandModel.InitialState.self)
            return
        }
        
        let state = internalRotationWithResistanceBandModel.currentState
        
        switch state {
        case state as InternalRotationWithResistanceBandModel.InitialState:
            initialProcessObservation(observation: observation)
            break
        case state as InternalRotationWithResistanceBandModel.CalibrationState:
            calibrationProcessObservation(observation: observation)
            break
        case state as InternalRotationWithResistanceBandModel.StartState:
            startProcessObservation(observation: observation)
            break
        case state as InternalRotationWithResistanceBandModel.RepetitionState:
            repetitionProcessObservation(observation: observation)
            break
        case state as InternalRotationWithResistanceBandModel.RepetitionInitialState:
            repetitionInitialProcessObservation(observation: observation)
            break
        case state as InternalRotationWithResistanceBandModel.RepetitionInProgressState:
            repetitionInProgressProcessObservation(observation: observation)
            break
        case state as InternalRotationWithResistanceBandModel.RepetitionCompletedState:
            repetitionCompletedProcessObservation(observation: observation)
            break
        default:
            break
        }
    }
    
    private func initialProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.internalRotationWithResistanceBandModel
        
        if model.instructed {
            model.enter(InternalRotationWithResistanceBandModel.CalibrationState.self)
        }
    }
    
    private func calibrationProcessObservation(observation: VNHumanBodyPoseObservation) {
        let result = InternalRotationWithResistanceBandStartClassifier.check(observation: observation)
        
        if result {
            self.internalRotationWithResistanceBandModel.enter(InternalRotationWithResistanceBandModel.StartState.self)
        }
    }
    
    private func startProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.internalRotationWithResistanceBandModel
        
        let result = InternalRotationWithResistanceBandInPositionClassifier.check(observation: observation)
        
        if !result {
            return
        }
        
        if model.firstRepetition {
            if model.enter(InternalRotationWithResistanceBandModel.InPositionState.self){
                    Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                        InternalRotationWithResistanceBandModel.sharedTimers.append(timer)
                        if model.startTimeLeft == 0 {
                            if model.enter(InternalRotationWithResistanceBandModel.RepetitionState.self) {
                                model.startTimeLeft = InternalRotationWithResistanceBandModel.startTime
                                timer.invalidate()
                            }
                        } else {
                            model.startTimeLeft -= 1
                        }
                    }
                }
            } else {
                model.enter(InternalRotationWithResistanceBandModel.RepetitionInitialState.self)
            }
    }
    
    private func repetitionProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.internalRotationWithResistanceBandModel
        
        if model.firstRepetition {
            model.enter(InternalRotationWithResistanceBandModel.RepetitionInitialState.self)
            return
        }
        
        if model.remainingSets <= 0 {
            if model.side == .both && model.currentSide == .right {
                model.updateToLeftSide()
                model.remainingSets = InternalRotationWithResistanceBandModel.sets
                model.remainingRepetitions = InternalRotationWithResistanceBandModel.repetitions
                model.enter(InternalRotationWithResistanceBandModel.StartState.self)
                return
            }
            model.transitionTimer = InternalRotationWithResistanceBandModel.transitionTime
            model.exerciseCompleted = true
            model.transitionTimerIsActive = true
            model.enter(InternalRotationWithResistanceBandModel.ExerciseEndState.self)
            return
        } else {
            model.enter(InternalRotationWithResistanceBandModel.StartState.self)
        }
    }
    
    private func repetitionInitialProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.internalRotationWithResistanceBandModel
        
        // Timer
        if (!model.isActivated) {
            model.isActivated = true
            repetitionTimer()
        }
        
        let result = InternalRotationWithResistanceBandRepetitionClassifier.check(observation: observation)
        
        if result {
            model.enter(InternalRotationWithResistanceBandModel.RepetitionInProgressState.self)
        }
    }

    private func repetitionInProgressProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.internalRotationWithResistanceBandModel
        
        InternalRotationWithResistanceBandRepetitionInProgressClassifier.check(observation: observation)
        
        if model.currentAngleFrames > 30 {
            model.leeway = 3
        } else {
            model.leeway = 1.5
        }
        if model.currentAngleFrames == 50 {
            model.currentAngleFrames = 0
            model.remainingRepetitions -= 1
            model.completedReps += 1
            if model.remainingRepetitions <= 0 {
                model.setCompleted = true
            }
            model.bufferTime = model.setCompleted ? model.setCompletedInterval : model.bufferInterval
            model.enter(InternalRotationWithResistanceBandModel.RepetitionCompletedState.self)
        }
    }
    
    private func repetitionCompletedProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.internalRotationWithResistanceBandModel
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { timer in
            if model.currentState!.description ==
                InternalRotationWithResistanceBandModel.RepetitionCompletedState().description {
                if model.bufferTime <= 0 {
                    if model.setCompleted {
                        model.remainingSets -= 1
                        model.completedSets += 1
                        model.remainingRepetitions = InternalRotationWithResistanceBandModel.repetitions
                        model.setCompleted = false
                    }
                    if model.firstRepetition {
                        model.firstRepetition = false
                    }
                    
                    if model.currentSide == .left && model.firstLeftRepetition {
                        model.firstLeftRepetition = false
                    }
                    model.enter(InternalRotationWithResistanceBandModel.RepetitionState.self)
                    
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
        let model = self.internalRotationWithResistanceBandModel
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if model.currentState!.description != InternalRotationWithResistanceBandModel.RepetitionInProgressState().description &&
                model.currentState!.description != InternalRotationWithResistanceBandModel.RepetitionState().description &&
                model.currentState!.description != InternalRotationWithResistanceBandModel.RepetitionInitialState().description {
                model.repetitionDurationLeft = InternalRotationWithResistanceBandModel.repetitionDuration
                timer.invalidate()
                return
            }
            
            // exerciseCompleted flag is set when either all reps and sets are completed, the user skips to the next exercise or the user exits back to the homepage.
            // If we don't check this, timer will continue to run even as the user moves on to somewhere else
            if model.exerciseCompleted {
                model.repetitionDurationLeft = InternalRotationWithResistanceBandModel.repetitionDuration
                model.isActivated = false
                timer.invalidate()
                return
            }
            if model.repetitionDurationLeft <= 0 {
                if !model.repetitionIsGood {
                    model.isGiveUp = true
                }
                model.repetitionDurationLeft = InternalRotationWithResistanceBandModel.repetitionDuration
                model.currentAngleFrames = 0
                model.remainingRepetitions -= 1
                model.completedReps += 1
                if model.remainingRepetitions <= 0 {
                    model.setCompleted = true
                }
                model.bufferTime = model.setCompleted ? model.setCompletedInterval : model.bufferInterval
                model.enter(InternalRotationWithResistanceBandModel.RepetitionCompletedState.self)
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
