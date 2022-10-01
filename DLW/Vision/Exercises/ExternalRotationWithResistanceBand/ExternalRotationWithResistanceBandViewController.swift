import AVFoundation
import Vision
import UIKit
import SwiftUI
import GameplayKit
import GameKit

class ExternalRotationWithResistanceBandViewController: CameraService {
    private var initial: Bool = true
    private var externalRotationWithResistanceBandModel: ExternalRotationWithResistanceBandModel = ExternalRotationWithResistanceBandModel.shared
    
    override var drawnJoints: [VNHumanBodyPoseObservation.JointName] {
        get {
            if externalRotationWithResistanceBandModel.side == .left || (externalRotationWithResistanceBandModel.currentSide == .left && externalRotationWithResistanceBandModel.side == .both) {
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
            if externalRotationWithResistanceBandModel.side == .left || (externalRotationWithResistanceBandModel.currentSide == .left && externalRotationWithResistanceBandModel.side == .both) {
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


extension ExternalRotationWithResistanceBandViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
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
        if externalRotationWithResistanceBandModel.currentState == nil {
            externalRotationWithResistanceBandModel.enter(ExternalRotationWithResistanceBandModel.InitialState.self)
            return
        }
        
        let state = externalRotationWithResistanceBandModel.currentState
        
        switch state {
        case state as ExternalRotationWithResistanceBandModel.InitialState:
            initialProcessObservation(observation: observation)
            break
        case state as ExternalRotationWithResistanceBandModel.CalibrationState:
            calibrationProcessObservation(observation: observation)
            break
        case state as ExternalRotationWithResistanceBandModel.StartState:
            startProcessObservation(observation: observation)
            break
        case state as ExternalRotationWithResistanceBandModel.RepetitionState:
            repetitionProcessObservation(observation: observation)
            break
        case state as ExternalRotationWithResistanceBandModel.RepetitionInitialState:
            repetitionInitialProcessObservation(observation: observation)
            break
        case state as ExternalRotationWithResistanceBandModel.RepetitionInProgressState:
            repetitionInProgressProcessObservation(observation: observation)
            break
        case state as ExternalRotationWithResistanceBandModel.RepetitionCompletedState:
            repetitionCompletedProcessObservation(observation: observation)
            break
        default:
            break
        }
    }
    
    private func initialProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.externalRotationWithResistanceBandModel
        
        if model.instructed {
            model.enter(ExternalRotationWithResistanceBandModel.CalibrationState.self)
        }
    }
    
    private func calibrationProcessObservation(observation: VNHumanBodyPoseObservation) {
        let result = ExternalRotationWithResistanceBandStartClassifier.check(observation: observation)
        
        if result {
            self.externalRotationWithResistanceBandModel.enter(ExternalRotationWithResistanceBandModel.StartState.self)
        }
    }
    
    private func startProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.externalRotationWithResistanceBandModel
        
        let result = ExternalRotationWithResistanceBandInPositionClassifier.check(observation: observation)
        
        if !result {
            return
        }
        
        if model.firstRepetition {
            if model.enter(ExternalRotationWithResistanceBandModel.InPositionState.self){
                    Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                        ExternalRotationWithResistanceBandModel.sharedTimers.append(timer)
                        if model.startTimeLeft == 0 {
                            if model.enter(ExternalRotationWithResistanceBandModel.RepetitionState.self) {
                                model.startTimeLeft = ExternalRotationWithResistanceBandModel.startTime
                                timer.invalidate()
                            }
                        } else {
                            model.startTimeLeft -= 1
                        }
                    }
                }
            } else {
                model.enter(ExternalRotationWithResistanceBandModel.RepetitionInitialState.self)
            }
    }
    
    private func repetitionProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.externalRotationWithResistanceBandModel
        
        if model.firstRepetition {
            model.enter(ExternalRotationWithResistanceBandModel.RepetitionInitialState.self)
            return
        }
        
        if model.remainingSets <= 0 {
            if model.side == .both && model.currentSide == .right {
                model.updateToLeftSide()
                model.remainingSets = ExternalRotationWithResistanceBandModel.sets
                model.remainingRepetitions = ExternalRotationWithResistanceBandModel.repetitions
                model.enter(ExternalRotationWithResistanceBandModel.StartState.self)
                return
            }
            model.transitionTimer = ExternalRotationWithResistanceBandModel.transitionTime
            model.exerciseCompleted = true
            model.transitionTimerIsActive = true
            model.enter(ExternalRotationWithResistanceBandModel.ExerciseEndState.self)
            return
        } else {
            model.enter(ExternalRotationWithResistanceBandModel.StartState.self)
        }
    }
    
    private func repetitionInitialProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.externalRotationWithResistanceBandModel
        
        // Timer
        if (!model.isActivated) {
            model.isActivated = true
            repetitionTimer()
        }
        
        let result = ExternalRotationWithResistanceBandRepetitionClassifier.check(observation: observation)
        
        if result {
            model.enter(ExternalRotationWithResistanceBandModel.RepetitionInProgressState.self)
        }
    }

    private func repetitionInProgressProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.externalRotationWithResistanceBandModel
        
        ExternalRotationWithResistanceBandRepetitionInProgressClassifier.check(observation: observation)
        
        if model.currentAngleFrames > 40 {
            model.leeway = 3
        } else {
            model.leeway = 1.5
        }
        if model.currentAngleFrames == 60 {
            model.currentAngleFrames = 0
            model.remainingRepetitions -= 1
            model.completedReps += 1
            if model.remainingRepetitions <= 0 {
                model.setCompleted = true
            }
            model.bufferTime = model.setCompleted ? model.setCompletedInterval : model.bufferInterval
            model.enter(ExternalRotationWithResistanceBandModel.RepetitionCompletedState.self)
        }
    }
    
    private func repetitionCompletedProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.externalRotationWithResistanceBandModel
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { timer in
            if model.currentState!.description ==
                ExternalRotationWithResistanceBandModel.RepetitionCompletedState().description {
                if model.bufferTime <= 0 {
                    if model.setCompleted {
                        model.remainingSets -= 1
                        model.completedSets += 1
                        model.remainingRepetitions = ExternalRotationWithResistanceBandModel.repetitions
                        model.setCompleted = false
                    }
                    if model.firstRepetition {
                        model.firstRepetition = false
                    }
                    
                    if model.currentSide == .left && model.firstLeftRepetition {
                        model.firstLeftRepetition = false
                    }
                    model.enter(ExternalRotationWithResistanceBandModel.RepetitionState.self)
                    
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
        let model = self.externalRotationWithResistanceBandModel
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if model.currentState!.description != ExternalRotationWithResistanceBandModel.RepetitionInProgressState().description &&
                model.currentState!.description != ExternalRotationWithResistanceBandModel.RepetitionState().description &&
                model.currentState!.description != ExternalRotationWithResistanceBandModel.RepetitionInitialState().description {
                model.repetitionDurationLeft = ExternalRotationWithResistanceBandModel.repetitionDuration
                timer.invalidate()
                return
            }
            
            // exerciseCompleted flag is set when either all reps and sets are completed, the user skips to the next exercise or the user exits back to the homepage.
            // If we don't check this, timer will continue to run even as the user moves on to somewhere else
            if model.exerciseCompleted {
                model.repetitionDurationLeft = ExternalRotationWithResistanceBandModel.repetitionDuration
                model.isActivated = false
                timer.invalidate()
                return
            }
            if model.repetitionDurationLeft <= 0 {
                if !model.repetitionIsGood {
                    model.isGiveUp = true
                }
                model.repetitionDurationLeft = ExternalRotationWithResistanceBandModel.repetitionDuration
                model.currentAngleFrames = 0
                model.remainingRepetitions -= 1
                model.completedReps += 1
                if model.remainingRepetitions <= 0 {
                    model.setCompleted = true
                }
                model.bufferTime = model.setCompleted ? model.setCompletedInterval : model.bufferInterval
                model.enter(ExternalRotationWithResistanceBandModel.RepetitionCompletedState.self)
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
