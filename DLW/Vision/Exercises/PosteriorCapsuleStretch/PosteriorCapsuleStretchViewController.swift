import AVFoundation
import Vision
import UIKit
import SwiftUI
import GameplayKit
import GameKit

class PosteriorCapsuleStretchViewController: CameraService {
    private var initial: Bool = true
    private var posteriorCapsuleStretchModel: PosteriorCapsuleStretchModel = PosteriorCapsuleStretchModel.shared
    
    override var drawnJoints: [VNHumanBodyPoseObservation.JointName] {
        get {
            return [
                .leftShoulder,
                .rightShoulder,
                .rightWrist,
                .rightElbow,
                .rightHip,
                .leftWrist,
                .leftElbow,
                .leftHip,
            ]
        }
    }
    
    override var drawnJointPairs: [[VNHumanBodyPoseObservation.JointName]] {
        get {
            return [
                [.rightHip, .rightShoulder],
                [.rightShoulder, .rightElbow],
                [.rightElbow, .rightWrist],
                [.leftHip, .leftShoulder],
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


extension PosteriorCapsuleStretchViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
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
        if posteriorCapsuleStretchModel.currentState == nil {
            posteriorCapsuleStretchModel.enter(PosteriorCapsuleStretchModel.InitialState.self)
            return
        }
        
        let state = posteriorCapsuleStretchModel.currentState
        
        switch state {
        case state as PosteriorCapsuleStretchModel.InitialState:
            initialProcessObservation(observation: observation)
            break
        case state as PosteriorCapsuleStretchModel.CalibrationState:
            calibrationProcessObservation(observation: observation)
            break
        case state as PosteriorCapsuleStretchModel.StartState:
            startProcessObservation(observation: observation)
            break
        case state as PosteriorCapsuleStretchModel.RepetitionState:
            repetitionProcessObservation(observation: observation)
            break
        case state as PosteriorCapsuleStretchModel.RepetitionInitialState:
            repetitionInitialProcessObservation(observation: observation)
            break
        case state as PosteriorCapsuleStretchModel.RepetitionInProgressState:
            repetitionInProgressProcessObservation(observation: observation)
            break
        case state as PosteriorCapsuleStretchModel.RepetitionCompletedState:
            repetitionCompletedProcessObservation(observation: observation)
            break
        default:
            break
        }
    }
    
    private func initialProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.posteriorCapsuleStretchModel
        
        if model.instructed {
            model.enter(PosteriorCapsuleStretchModel.CalibrationState.self)
        }
    }
    
    private func calibrationProcessObservation(observation: VNHumanBodyPoseObservation) {
        let result = PosteriorCapsuleStretchStartClassifier.check(observation: observation)
        
        if result {
            self.posteriorCapsuleStretchModel.enter(PosteriorCapsuleStretchModel.StartState.self)
        }
    }
    
    private func startProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.posteriorCapsuleStretchModel
        let result = PosteriorCapsuleStretchInPositionClassifier.check(observation: observation)
        
        if !result {
            return
        }
        
        if model.firstRepetition {
            if model.enter(PosteriorCapsuleStretchModel.InPositionState.self){
                    Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                        PosteriorCapsuleStretchModel.sharedTimers.append(timer)
                        if model.startTimeLeft == 0 {
                            if model.enter(PosteriorCapsuleStretchModel.RepetitionState.self) {
                                model.startTimeLeft = PosteriorCapsuleStretchModel.startTime
                                timer.invalidate()
                            }
                        } else {
                            model.startTimeLeft -= 1
                        }
                    }
                }
            } else {
                model.enter(PosteriorCapsuleStretchModel.RepetitionInitialState.self)
            }
    }
    
    private func repetitionProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.posteriorCapsuleStretchModel
        
        if model.firstRepetition {
            model.enter(PosteriorCapsuleStretchModel.RepetitionInitialState.self)
            return
        }
        
        if model.remainingSets <= 0 {
            if model.side == .both && model.currentSide == .right {
                model.updateToLeftSide()
                model.remainingSets = PosteriorCapsuleStretchModel.sets
                model.remainingRepetitions = PosteriorCapsuleStretchModel.repetitions
                model.enter(PosteriorCapsuleStretchModel.StartState.self)
                return
            }
            model.transitionTimer = PosteriorCapsuleStretchModel.transitionTime
            model.exerciseCompleted = true
            model.transitionTimerIsActive = true
            model.enter(PosteriorCapsuleStretchModel.ExerciseEndState.self)
            return
        } else {
            model.enter(PosteriorCapsuleStretchModel.StartState.self)
        }
    }
    
    private func repetitionInitialProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.posteriorCapsuleStretchModel
        let result = PosteriorCapsuleStretchRepetitionClassifier.check(observation: observation)
        
        if result {
            model.enter(PosteriorCapsuleStretchModel.RepetitionInProgressState.self)
            repetitionTimer()
        }
    }

    private func repetitionInProgressProcessObservation(observation: VNHumanBodyPoseObservation) {
        PosteriorCapsuleStretchRepetitionInProgressClassifier.check(observation: observation)
    }
    
    private func repetitionCompletedProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.posteriorCapsuleStretchModel
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { timer in
            if model.currentState!.description ==
                PosteriorCapsuleStretchModel.RepetitionCompletedState().description {
                if model.bufferTime <= 0 {
                    if model.setCompleted {
                        model.remainingSets -= 1
                        model.completedSets += 1
                        model.remainingRepetitions = PosteriorCapsuleStretchModel.repetitions
                        model.setCompleted = false
                    }
                    if model.firstRepetition {
                        model.firstRepetition = false
                    }
                    model.enter(PosteriorCapsuleStretchModel.RepetitionState.self)
                    timer.invalidate()
                } else {
                    model.bufferTime -= 0.1
                }
            }
        }
    }
    
    func repetitionTimer() {
        let model = self.posteriorCapsuleStretchModel
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if model.currentState!.description != PosteriorCapsuleStretchModel.RepetitionInProgressState().description {
                timer.invalidate()
                return
            }
            
            // exerciseCompleted flag is set when either all reps and sets are completed, the user skips to the next exercise or the user exits back to the homepage.
            // If we don't check this, timer will continue to run even as the user moves on to somewhere else
            if model.exerciseCompleted {
                timer.invalidate()
                return
            }
            
            PosteriorCapsuleStretchModel.sharedTimers.append(timer)
            if Int(model.repetitionDurationLeft) <= 0 {
                model.remainingRepetitions -= 1
                model.completedReps += 1
                if model.remainingRepetitions <= 0 {
                    model.setCompleted = true
                }
                model.bufferTime = model.setCompleted ? model.setCompletedInterval : model.bufferInterval
                model.enter(PosteriorCapsuleStretchModel.RepetitionCompletedState.self)
                model.repetitionDurationLeft = PosteriorCapsuleStretchModel.repetitionDuration
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
