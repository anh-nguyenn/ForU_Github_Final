import AVFoundation
import Vision
import UIKit
import SwiftUI
import GameplayKit
import GameKit

class AssistedKneeExtensionViewController: CameraService {
    private var initial: Bool = true
    private var assistedKneeExtensionModel: AssistedKneeExtensionModel = AssistedKneeExtensionModel.shared
    
    override var drawnJoints: [VNHumanBodyPoseObservation.JointName] {
        get {
            if assistedKneeExtensionModel.side == .left || (assistedKneeExtensionModel.currentSide == .left && assistedKneeExtensionModel.side == .both) {
                return [
                    .rightHip,
                    .rightKnee,
                    .rightAnkle,
                ]
            } else {
                return [
                    .leftHip,
                    .leftKnee,
                    .leftAnkle,
                ]
            }
        }
    }
    
    override var drawnJointPairs: [[VNHumanBodyPoseObservation.JointName]] {
        get {
            if assistedKneeExtensionModel.side == .left || (assistedKneeExtensionModel.currentSide == .left && assistedKneeExtensionModel.side == .both) {
                return [
                    [.rightHip, .rightKnee],
                    [.rightKnee, .rightAnkle]
                ]
            } else {
                return [
                    [.leftHip, .leftKnee],
                    [.leftKnee, .leftAnkle]
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


extension AssistedKneeExtensionViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
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
        if assistedKneeExtensionModel.currentState == nil {
            assistedKneeExtensionModel.enter(AssistedKneeExtensionModel.InitialState.self)
            return
        }
        
        let state = assistedKneeExtensionModel.currentState
        
        switch state {
        case state as AssistedKneeExtensionModel.InitialState:
            initialProcessObservation(observation: observation)
            break
        case state as AssistedKneeExtensionModel.CalibrationState:
            calibrationProcessObservation(observation: observation)
            break
        case state as AssistedKneeExtensionModel.StartState:
            startProcessObservation(observation: observation)
            break
        case state as AssistedKneeExtensionModel.RepetitionState:
            repetitionProcessObservation(observation: observation)
            break
        case state as AssistedKneeExtensionModel.RepetitionInitialState:
            repetitionInitialProcessObservation(observation: observation)
            break
        case state as AssistedKneeExtensionModel.RepetitionInProgressState:
            repetitionInProgressProcessObservation(observation: observation)
            break
        case state as AssistedKneeExtensionModel.RepetitionCompletedState:
            repetitionCompletedProcessObservation(observation: observation)
            break
        default:
            break
        }
    }
    
    private func initialProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.assistedKneeExtensionModel
        
        if model.instructed {
            model.enter(AssistedKneeExtensionModel.CalibrationState.self)
        }
    }
    
    private func calibrationProcessObservation(observation: VNHumanBodyPoseObservation) {
        let result = AssistedKneeExtensionStartClassifier.check(observation: observation)
        
        if result {
            self.assistedKneeExtensionModel.enter(AssistedKneeExtensionModel.StartState.self)
        }
    }
    
    private func startProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.assistedKneeExtensionModel
        
        let result = AssistedKneeExtensionInPositionClassifier.check(observation: observation)
        
        if !result {
            return
        }
        
        if model.firstRepetition {
            if model.enter(AssistedKneeExtensionModel.InPositionState.self){
                    Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                        AssistedKneeExtensionModel.sharedTimers.append(timer)
                        if model.startTimeLeft == 0 {
                            if model.enter(AssistedKneeExtensionModel.RepetitionState.self) {
                                model.startTimeLeft = AssistedKneeExtensionModel.startTime
                                timer.invalidate()
                            }
                        } else {
                            model.startTimeLeft -= 1
                        }
                    }
                }
            } else {
                model.enter(AssistedKneeExtensionModel.RepetitionInitialState.self)
            }
    }
    
    private func repetitionProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.assistedKneeExtensionModel
        
        if model.firstRepetition {
            model.enter(AssistedKneeExtensionModel.RepetitionInitialState.self)
            return
        }
        
        if model.remainingSets <= 0 {
            if model.side == .both && model.currentSide == .right {
                model.updateToLeftSide()
                model.remainingSets = AssistedKneeExtensionModel.sets
                model.remainingRepetitions = AssistedKneeExtensionModel.repetitions
                model.enter(AssistedKneeExtensionModel.StartState.self)
                return
            }
            model.transitionTimer = AssistedKneeExtensionModel.transitionTime
            model.exerciseCompleted = true
            model.transitionTimerIsActive = true
            model.enter(AssistedKneeExtensionModel.ExerciseEndState.self)
            return
        } else {
            model.enter(AssistedKneeExtensionModel.StartState.self)
        }
    }
    
    private func repetitionInitialProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.assistedKneeExtensionModel
        
        // Timer
        if (!model.isActivated) {
            model.isActivated = true
            repetitionTimer()
        }
        
        let result = AssistedKneeExtensionRepetitionClassifier.check(observation: observation)
        
        if result {
            model.enter(AssistedKneeExtensionModel.RepetitionInProgressState.self)
        }
    }

    private func repetitionInProgressProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.assistedKneeExtensionModel
        
        AssistedKneeExtensionRepetitionInProgressClassifier.check(observation: observation)
        
        if model.currentAngleFrames > 40 {
            model.leeway = 3
        } else {
            model.leeway = 1.5
        }
        if model.currentAngleFrames == 120 {
            model.currentAngleFrames = 0
            model.remainingRepetitions -= 1
            model.completedReps += 1
            if model.remainingRepetitions <= 0 {
                model.setCompleted = true
            }
            model.bufferTime = model.setCompleted ? model.setCompletedInterval : model.bufferInterval
            model.enter(AssistedKneeExtensionModel.RepetitionCompletedState.self)
        }
    }
    
    private func repetitionCompletedProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.assistedKneeExtensionModel
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { timer in
            if model.currentState!.description ==
                AssistedKneeExtensionModel.RepetitionCompletedState().description {
                if model.bufferTime <= 0 {
                    if model.setCompleted {
                        model.remainingSets -= 1
                        model.completedSets += 1
                        model.remainingRepetitions = AssistedKneeExtensionModel.repetitions
                        model.setCompleted = false
                    }
                    if model.firstRepetition {
                        model.firstRepetition = false
                    }
                    
                    if model.currentSide == .left && model.firstLeftRepetition {
                        model.firstLeftRepetition = false
                    }
                    model.enter(AssistedKneeExtensionModel.RepetitionState.self)
                    
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
        let model = self.assistedKneeExtensionModel
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if model.currentState!.description != AssistedKneeExtensionModel.RepetitionInProgressState().description &&
                model.currentState!.description != AssistedKneeExtensionModel.RepetitionState().description &&
                model.currentState!.description != AssistedKneeExtensionModel.RepetitionInitialState().description {
                model.repetitionDurationLeft = AssistedKneeExtensionModel.repetitionDuration
                timer.invalidate()
                return
            }
            
            // exerciseCompleted flag is set when either all reps and sets are completed, the user skips to the next exercise or the user exits back to the homepage.
            // If we don't check this, timer will continue to run even as the user moves on to somewhere else
            if model.exerciseCompleted {
                model.repetitionDurationLeft = AssistedKneeExtensionModel.repetitionDuration
                model.isActivated = false
                timer.invalidate()
                return
            }
            if model.repetitionDurationLeft <= 0 {
                model.isGiveUp = true
                model.repetitionDurationLeft = AssistedKneeExtensionModel.repetitionDuration
                model.currentAngleFrames = 0
                model.remainingRepetitions -= 1
                model.completedReps += 1
                if model.remainingRepetitions <= 0 {
                    model.setCompleted = true
                }
                model.bufferTime = model.setCompleted ? model.setCompletedInterval : model.bufferInterval
                model.enter(AssistedKneeExtensionModel.RepetitionCompletedState.self)
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

