import AVFoundation
import Vision
import UIKit
import SwiftUI
import GameplayKit
import GameKit

class BandedRotationViewController: CameraService {
    private var initial: Bool = true
    private var bandedRotationModel: BandedRotationModel = BandedRotationModel.shared
    
    override var drawnJoints: [VNHumanBodyPoseObservation.JointName] {
        get {
            return [
                .leftShoulder,
                .rightShoulder,
                .rightWrist,
                .rightElbow,
                .leftWrist,
                .leftElbow,
            ]
        }
    }
    
    override var drawnJointPairs: [[VNHumanBodyPoseObservation.JointName]] {
        get {
            return [
                [.rightShoulder, .rightElbow],
                [.rightElbow, .rightWrist],
                [.leftShoulder, .leftElbow],
                [.leftElbow, .leftWrist]
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


extension BandedRotationViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
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
        if bandedRotationModel.currentState == nil {
            bandedRotationModel.enter(BandedRotationModel.InitialState.self)
            return
        }
        
        let state = bandedRotationModel.currentState
        
        switch state {
        case state as BandedRotationModel.InitialState:
            initialProcessObservation(observation: observation)
            break
        case state as BandedRotationModel.CalibrationState:
            calibrationProcessObservation(observation: observation)
            break
        case state as BandedRotationModel.StartState:
            startProcessObservation(observation: observation)
            break
        case state as BandedRotationModel.RepetitionState:
            repetitionProcessObservation(observation: observation)
            break
        case state as BandedRotationModel.RepetitionInitialState:
            repetitionInitialProcessObservation(observation: observation)
            break
        case state as BandedRotationModel.RepetitionInProgressState:
            repetitionInProgressProcessObservation(observation: observation)
            break
        case state as BandedRotationModel.RepetitionCompletedState:
            repetitionCompletedProcessObservation(observation: observation)
            break
        default:
            break
        }
    }
    
    private func initialProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.bandedRotationModel
        
        if model.instructed {
            model.enter(BandedRotationModel.CalibrationState.self)
        }
    }
    
    private func calibrationProcessObservation(observation: VNHumanBodyPoseObservation) {
        let result = BandedRotationStartClassifier.check(observation: observation)
        
        if result {
            self.bandedRotationModel.enter(BandedRotationModel.StartState.self)
        }
    }
    
    private func startProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.bandedRotationModel
        
        let result = BandedRotationInPositionClassifier.check(observation: observation)
        
        if !result {
            return
        }
        
        if model.firstRepetition {
            if model.enter(BandedRotationModel.InPositionState.self){
                    Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                        BandedRotationModel.sharedTimers.append(timer)
                        if model.startTimeLeft == 0 {
                            if model.enter(BandedRotationModel.RepetitionState.self) {
                                model.startTimeLeft = BandedRotationModel.startTime
                                timer.invalidate()
                            }
                        } else {
                            model.startTimeLeft -= 1
                        }
                    }
                }
            } else {
                model.enter(BandedRotationModel.RepetitionInitialState.self)
            }
    }
    
    private func repetitionProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.bandedRotationModel
        
        if model.firstRepetition {
            model.enter(BandedRotationModel.RepetitionInitialState.self)
            return
        }
        
        if model.remainingSets <= 0 {
            model.transitionTimer = BandedRotationModel.transitionTime
            model.exerciseCompleted = true
            model.transitionTimerIsActive = true
            model.enter(BandedRotationModel.ExerciseEndState.self)
            return
        } else {
            model.enter(BandedRotationModel.StartState.self)
        }
    }
    
    private func repetitionInitialProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.bandedRotationModel
        
        // ADD TIMER
        if !model.isActivated {
            model.isActivated = true
            repetitionTimer()
        }

        let result = BandedRotationRepetitionClassifier.check(observation: observation)
        
        if result {
            model.enter(BandedRotationModel.RepetitionInProgressState.self)
        }
    }

    private func repetitionInProgressProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.bandedRotationModel
        
        BandedRotationRepetitionInProgressClassifier.check(observation: observation)
        
        if model.currentAngleFrames > 40 {
            model.leeway = 0.3
        } else {
            model.leeway = 0.1
        }
        
        if model.currentAngleFrames == 70 {
            model.currentAngleFrames = 0
            model.lastLeftRatio = 0
            model.lastRightRatio = 0
            model.remainingRepetitions -= 1
            model.completedReps += 1
            if model.remainingRepetitions <= 0 {
                model.setCompleted = true
            }
            model.bufferTime = model.setCompleted ? model.setCompletedInterval : model.bufferInterval
            model.enter(BandedRotationModel.RepetitionCompletedState.self)
        }
    }
    
    private func repetitionCompletedProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.bandedRotationModel
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { timer in
            if model.currentState!.description ==
                BandedRotationModel.RepetitionCompletedState().description {
                if model.bufferTime <= 0 {
                    if model.setCompleted {
                        model.remainingSets -= 1
                        model.completedSets += 1
                        model.remainingRepetitions = BandedRotationModel.repetitions
                        model.setCompleted = false
                    }
                    if model.firstRepetition {
                        model.firstRepetition = false
                    }
                    model.enter(BandedRotationModel.RepetitionState.self)
                    
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
        let model = self.bandedRotationModel
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if model.currentState!.description != BandedRotationModel.RepetitionInProgressState().description &&
                model.currentState!.description != BandedRotationModel.RepetitionState().description &&
                model.currentState!.description != BandedRotationModel.RepetitionInitialState().description {
                model.repetitionDurationLeft = BandedRotationModel.repetitionDuration
                timer.invalidate()
                return
            }
            
            // exerciseCompleted flag is set when either all reps and sets are completed, the user skips to the next exercise or the user exits back to the homepage.
            // If we don't check this, timer will continue to run even as the user moves on to somewhere else
            if model.exerciseCompleted {
                model.repetitionDurationLeft = BandedRotationModel.repetitionDuration
                model.isActivated = false
                timer.invalidate()
                return
            }
            
            if model.repetitionDurationLeft <= 0 {
                if !model.repetitionIsGood {
                    model.isGiveUp = true
                }
                model.repetitionDurationLeft = BandedRotationModel.repetitionDuration
                model.currentAngleFrames = 0
                model.remainingRepetitions -= 1
                model.completedReps += 1
                if model.remainingRepetitions <= 0 {
                    model.setCompleted = true
                }
                model.bufferTime = model.setCompleted ? model.setCompletedInterval : model.bufferInterval
                model.enter(BandedRotationModel.RepetitionCompletedState.self)
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
