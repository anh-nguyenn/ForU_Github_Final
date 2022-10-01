import AVFoundation
import Vision
import UIKit
import SwiftUI
import GameplayKit
import GameKit

class ShoulderHorizontalAbductionViewController: CameraService {
    private var initial: Bool = true
    private var shoulderHorizontalAbductionModel: ShoulderHorizontalAbductionModel = ShoulderHorizontalAbductionModel.shared
    
    override var drawnJoints: [VNHumanBodyPoseObservation.JointName] {
        get {
            return [
                .rightShoulder,
                .rightElbow,
                .leftShoulder,
                .leftElbow,
            ]
        }
    }
    
    override var drawnJointPairs: [[VNHumanBodyPoseObservation.JointName]] {
        get {
            return [
                [.rightElbow, .rightShoulder],
                [.rightShoulder, .leftShoulder],
                [.leftShoulder, .leftElbow]
            ]
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


extension ShoulderHorizontalAbductionViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

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
        if shoulderHorizontalAbductionModel.currentState == nil {
            shoulderHorizontalAbductionModel.enter(ShoulderHorizontalAbductionModel.InitialState.self)
            return
        }
        
        let state = shoulderHorizontalAbductionModel.currentState
        
        switch state {
        case state as ShoulderHorizontalAbductionModel.InitialState:
            initialProcessObservation(observation: observation)
            break
        case state as ShoulderHorizontalAbductionModel.CalibrationState:
            calibrationProcessObservation(observation: observation)
            break
        case state as ShoulderHorizontalAbductionModel.StartState:
            startProcessObservation(observation: observation)
            break
        case state as ShoulderHorizontalAbductionModel.RepetitionState:
            repetitionProcessObservation(observation: observation)
            break
        case state as ShoulderHorizontalAbductionModel.RepetitionInitialState:
            repetitionInitialProcessObservation(observation: observation)
            break
        case state as ShoulderHorizontalAbductionModel.RepetitionInProgressState:
            repetitionInProgressProcessObservation(observation: observation)
            break
        case state as ShoulderHorizontalAbductionModel.RepetitionCompletedState:
            repetitionCompletedProcessObservation(observation: observation)
            break
        default:
            break
        }
    }
    
    private func initialProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.shoulderHorizontalAbductionModel
        
        if model.instructed {
            model.enter(ShoulderHorizontalAbductionModel.CalibrationState.self)
        }
    }
    
    private func calibrationProcessObservation(observation: VNHumanBodyPoseObservation) {
        let result = ShoulderHorizontalAbductionStartClassifier.check(observation: observation)
        
        if result {
            self.shoulderHorizontalAbductionModel.enter(ShoulderHorizontalAbductionModel.StartState.self)
        }
    }
    
    private func startProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.shoulderHorizontalAbductionModel
        let result = ShoulderHorizontalAbductionInPositionClassifier.check(observation: observation)
        
        if !result {
            return
        }
        
        if model.firstRepetition {
            if model.enter(ShoulderHorizontalAbductionModel.InPositionState.self){
                    Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                        ShoulderHorizontalAbductionModel.sharedTimers.append(timer)
                        if model.startTimeLeft == 0 {
                            if model.enter(ShoulderHorizontalAbductionModel.RepetitionState.self) {
                                model.startTimeLeft = ShoulderHorizontalAbductionModel.startTime
                                timer.invalidate()
                            }
                        } else {
                            model.startTimeLeft -= 1
                        }
                    }
                }
        } else {
            model.enter(ShoulderHorizontalAbductionModel.RepetitionInitialState.self)
        }
    }
    
    private func repetitionProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.shoulderHorizontalAbductionModel
        
        if model.firstRepetition {
            model.enter(ShoulderHorizontalAbductionModel.RepetitionInitialState.self)
            return
        }
        
        if model.remainingSets <= 0 {
            model.transitionTimer = ShoulderHorizontalAbductionModel.transitionTime
            model.exerciseCompleted = true
            model.transitionTimerIsActive = true
            model.enter(ShoulderHorizontalAbductionModel.ExerciseEndState.self)
            return
        } else {
            model.enter(ShoulderHorizontalAbductionModel.StartState.self)
        }
    }
    
    private func repetitionInitialProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.shoulderHorizontalAbductionModel
        
        // Timer
        if (!model.isActivated) {
            model.isActivated = true
            repetitionTimer()
        }
        
        let result = ShoulderHorizontalAbductionRepetitionClassifier.check(observation: observation)
        
        if result {
            model.enter(ShoulderHorizontalAbductionModel.RepetitionInProgressState.self)
        }
    }

    private func repetitionInProgressProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.shoulderHorizontalAbductionModel
        
        ShoulderHorizontalAbductionRepetitionInProgressClassifier.check(observation: observation)
        
        if model.currentAngleFrames > 40 {
            model.leeway = 0.05
        } else {
            model.leeway = 0.02
        }
        
        if model.currentAngleFrames == 80 {
            model.currentAngleFrames = 0
            model.remainingRepetitions -= 1
            model.completedReps += 1
            if model.remainingRepetitions <= 0 {
                model.setCompleted = true
            }
            model.bufferTime = model.setCompleted ? model.setCompletedInterval : model.bufferInterval
            model.enter(ShoulderHorizontalAbductionModel.RepetitionCompletedState.self)
        }
    }
    
    private func repetitionCompletedProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.shoulderHorizontalAbductionModel
        
        // repetitionDurationLeft gets resetted in completed state as doing it in the repetitionTimer function will make the countdownview show the timer reset at the last second
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { timer in
            if model.currentState!.description ==
                ShoulderHorizontalAbductionModel.RepetitionCompletedState().description {
                if model.bufferTime <= 0 {
                    if model.setCompleted {
                        model.remainingSets -= 1
                        model.completedSets += 1
                        model.remainingRepetitions = ShoulderHorizontalAbductionModel.repetitions
                        model.setCompleted = false
                    }
                    if model.firstRepetition {
                        model.firstRepetition = false
                    }
                    model.enter(ShoulderHorizontalAbductionModel.RepetitionState.self)
                    
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
        let model = self.shoulderHorizontalAbductionModel
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if model.currentState!.description != ShoulderHorizontalAbductionModel.RepetitionInProgressState().description &&
                model.currentState!.description != ShoulderHorizontalAbductionModel.RepetitionState().description &&
                model.currentState!.description != ShoulderHorizontalAbductionModel.RepetitionInitialState().description {
                model.repetitionDurationLeft = ShoulderHorizontalAbductionModel.repetitionDuration
                timer.invalidate()
                return
            }
            
            // exerciseCompleted flag is set when either all reps and sets are completed, the user skips to the next exercise or the user exits back to the homepage.
            // If we don't check this, timer will continue to run even as the user moves on to somewhere else
            if model.exerciseCompleted {
                model.isActivated = false
                timer.invalidate()
                return
            }
            
            if model.repetitionDurationLeft <= 0 {
                if !model.repetitionIsGood {
                    model.isGiveUp = true
                }
                model.repetitionDurationLeft = ShoulderHorizontalAbductionModel.repetitionDuration
                model.currentAngleFrames = 0
                model.remainingRepetitions -= 1
                model.completedReps += 1
                if model.remainingRepetitions <= 0 {
                    model.setCompleted = true
                }
                model.bufferTime = model.setCompleted ? model.setCompletedInterval : model.bufferInterval
                model.enter(ShoulderHorizontalAbductionModel.RepetitionCompletedState.self)
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
