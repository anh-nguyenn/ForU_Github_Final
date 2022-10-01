import AVFoundation
import Vision
import UIKit
import SwiftUI
import GameplayKit
import GameKit

class StandingKneeBendViewController: CameraService {
    private var initial: Bool = true
    private var standingKneeBendModel: StandingKneeBendModel = StandingKneeBendModel.shared
    
    override var drawnJoints: [VNHumanBodyPoseObservation.JointName] {
        get {
            if standingKneeBendModel.side == .left || (standingKneeBendModel.currentSide == .left && standingKneeBendModel.side == .both) {
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
            if standingKneeBendModel.side == .left || (standingKneeBendModel.currentSide == .left && standingKneeBendModel.side == .both) {
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


extension StandingKneeBendViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
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
        if standingKneeBendModel.currentState == nil {
            standingKneeBendModel.enter(StandingKneeBendModel.InitialState.self)
            return
        }
        
        let state = standingKneeBendModel.currentState
        
        switch state {
        case state as StandingKneeBendModel.InitialState:
            initialProcessObservation(observation: observation)
            break
        case state as StandingKneeBendModel.CalibrationState:
            calibrationProcessObservation(observation: observation)
            break
        case state as StandingKneeBendModel.StartState:
            startProcessObservation(observation: observation)
            break
        case state as StandingKneeBendModel.RepetitionState:
            repetitionProcessObservation(observation: observation)
            break
        case state as StandingKneeBendModel.RepetitionInitialState:
            repetitionInitialProcessObservation(observation: observation)
            break
        case state as StandingKneeBendModel.RepetitionInProgressState:
            repetitionInProgressProcessObservation(observation: observation)
            break
        case state as StandingKneeBendModel.RepetitionCompletedState:
            repetitionCompletedProcessObservation(observation: observation)
            break
        default:
            break
        }
    }
    
    private func initialProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.standingKneeBendModel
        
        if model.instructed {
            model.enter(StandingKneeBendModel.CalibrationState.self)
        }
    }
    
    private func calibrationProcessObservation(observation: VNHumanBodyPoseObservation) {
        let result = StandingKneeBendStartClassifier.check(observation: observation)
        
        if result {
            self.standingKneeBendModel.enter(StandingKneeBendModel.StartState.self)
        }
    }
    
    private func startProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.standingKneeBendModel
        
        let result = StandingKneeBendInPositionClassifier.check(observation: observation)
        
        if !result {
            return
        }
        
        if model.firstRepetition {
            if model.enter(StandingKneeBendModel.InPositionState.self){
                    Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                        StandingKneeBendModel.sharedTimers.append(timer)
                        if model.startTimeLeft == 0 {
                            if model.enter(StandingKneeBendModel.RepetitionState.self) {
                                model.startTimeLeft = StandingKneeBendModel.startTime
                                timer.invalidate()
                            }
                        } else {
                            model.startTimeLeft -= 1
                        }
                    }
                }
            } else {
                model.enter(StandingKneeBendModel.RepetitionInitialState.self)
            }
    }
    
    private func repetitionProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.standingKneeBendModel
        
        if model.firstRepetition {
            model.enter(StandingKneeBendModel.RepetitionInitialState.self)
            return
        }
        
        // Resets the good frames and bad frames from the previous rep
        model.goodFrames = 0
        model.badFrames = 0
        
        if model.remainingSets <= 0 {
            if model.side == .both && model.currentSide == .right {
                model.updateToLeftSide()
                model.remainingSets = StandingKneeBendModel.sets
                model.remainingRepetitions = StandingKneeBendModel.repetitions
                model.enter(StandingKneeBendModel.StartState.self)
                return
            }
            model.transitionTimer = StandingKneeBendModel.transitionTime
            model.exerciseCompleted = true
            model.transitionTimerIsActive = true
            model.enter(StandingKneeBendModel.ExerciseEndState.self)
            return
        } else {
            model.enter(StandingKneeBendModel.RepetitionInitialState.self)
        }
    }
    
    private func repetitionInitialProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.standingKneeBendModel
        
        let result = StandingKneeBendRepetitionClassifier.check(observation: observation)
        
        if result {
            if model.enter(StandingKneeBendModel.RepetitionInProgressState.self) {
                repetitionTimer()
            }
        }
    }

    private func repetitionInProgressProcessObservation(observation: VNHumanBodyPoseObservation) {
        StandingKneeBendRepetitionInProgressClassifier.check(observation: observation)
    }
    
    private func repetitionCompletedProcessObservation(observation: VNHumanBodyPoseObservation) {
        let model = self.standingKneeBendModel
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { timer in
            if model.currentState!.description ==
                StandingKneeBendModel.RepetitionCompletedState().description {
                if model.bufferTime <= 0 {
                    if model.setCompleted {
                        model.remainingSets -= 1
                        model.completedSets += 1
                        model.remainingRepetitions = StandingKneeBendModel.repetitions
                        model.setCompleted = false
                    }
                    if model.firstRepetition {
                        model.firstRepetition = false
                    }
                    
                    if model.currentSide == .left && model.firstLeftRepetition {
                        model.firstLeftRepetition = false
                    }
                    model.enter(StandingKneeBendModel.RepetitionState.self)
                    timer.invalidate()
                } else {
                    model.bufferTime -= 0.1
                }
            }
        }
    }
    
    // Timer
    private func repetitionTimer() {
           let model = self.standingKneeBendModel

           Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
               if model.currentState!.description != StandingKneeBendModel.RepetitionInProgressState().description {
                   timer.invalidate()
                   return
               }
               // exerciseCompleted flag is set when either all reps and sets are completed, the user skips to the next exercise or the user exits back to the homepage.
               // If we don't check this, timer will continue to run even as the user moves on to somewhere else
               if model.exerciseCompleted {
                   timer.invalidate()
                   return
               }
               
               StandingKneeBendModel.sharedTimers.append(timer)
               if Int(model.repetitionDurationLeft) == 0 {
                   model.completedReps += 1
                   model.remainingRepetitions -= 1
                   if model.remainingRepetitions <= 0 {
                       model.setCompleted = true
                   }
                   model.bufferTime = model.setCompleted ? model.setCompletedInterval : model.bufferInterval
                   if model.enter(StandingKneeBendModel.RepetitionCompletedState.self) {
                       model.repetitionDurationLeft = StandingKneeBendModel.repetitionDuration
                       timer.invalidate()
                       return
                   }
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

